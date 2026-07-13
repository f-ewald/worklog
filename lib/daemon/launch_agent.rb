# frozen_string_literal: true

require 'fileutils'
require 'rbconfig'
require 'thor'

require 'configuration'

module Worklog
  # Namespace for the worklogd background agent.
  module Daemon
    # Manages the macOS launchd LaunchAgent that runs `worklogd sync` on a
    # schedule. Filesystem paths are computed from `Dir.home` at call time so
    # they respect test stubs. Uses the modern `launchctl bootstrap`/`bootout`/
    # `print` subcommands rather than the deprecated `load`/`unload`.
    module LaunchAgent
      # Reverse-DNS launchd job label.
      LABEL = 'com.fewald.worklogd'

      # Default seconds between syncs (one hour).
      DEFAULT_INTERVAL = 3600

      # Absolute path of the generated LaunchAgent plist.
      # @return [String]
      def self.plist_path = File.join(Dir.home, 'Library', 'LaunchAgents', "#{LABEL}.plist")

      # Absolute path of the rotating daemon log (owned by WorkLogger).
      # @return [String]
      def self.log_path = File.join(Dir.home, 'Library', 'Logs', 'worklogd.log')

      # Absolute path launchd uses for early stderr (crashes before the logger inits).
      # @return [String]
      def self.err_path = File.join(Dir.home, 'Library', 'Logs', 'worklogd.err')

      # Absolute path of the single-instance lock file.
      # @return [String]
      def self.lock_path = File.join(Dir.home, '.worklog', 'worklogd.lock')

      # launchd per-user GUI domain, e.g. "gui/501".
      # @return [String]
      def self.domain = "gui/#{Process.uid}"

      # Fully-qualified service target, e.g. "gui/501/com.fewald.worklogd".
      # @return [String]
      def self.service_target = "#{domain}/#{LABEL}"

      # Absolute path of the Ruby interpreter currently running. Baked into the
      # plist so launchd never depends on PATH or an asdf shim.
      # @return [String]
      def self.ruby_path = RbConfig.ruby

      # Absolute path of the installed `worklogd` executable. Falls back to the
      # running script when the gem is not installed (development/source runs).
      # @return [String]
      def self.script_path
        Gem.bin_path('fewald-worklog', 'worklogd')
      rescue StandardError
        resolved_program_path
      end

      # Resolve $PROGRAM_NAME to an absolute path, tolerating non-file values
      # (e.g. "-e" when Ruby runs an inline script under the test runner).
      # @return [String]
      def self.resolved_program_path
        File.realpath($PROGRAM_NAME)
      rescue StandardError
        File.expand_path($PROGRAM_NAME)
      end

      # Write the plist and (re)load it via launchctl. Idempotent: any existing
      # job is booted out first. RunAtLoad triggers an immediate first sync.
      # @param interval [Integer] Seconds between syncs.
      # @param config [Worklog::Configuration] Used to detect Postgres env needs.
      # @return [void]
      def self.install!(interval: DEFAULT_INTERVAL, config: ::Worklog::Configuration.load)
        FileUtils.mkdir_p(File.dirname(plist_path))
        FileUtils.mkdir_p(File.dirname(log_path))
        File.write(plist_path, plist_xml(interval: interval, config: config))
        reload!
      end

      # Unload the job (if loaded) and remove the plist.
      # @return [void]
      def self.uninstall!
        launchctl('bootout', service_target)
        FileUtils.rm_f(plist_path)
      end

      # @return [Boolean] true when launchd currently has the job loaded.
      def self.loaded? = launchctl('print', service_target)

      # Trailing lines of the daemon log, for `worklogd status`.
      # @param lines [Integer] Number of trailing lines to return.
      # @return [Array<String>] Chomped log lines (empty when no log exists yet).
      def self.tail_log(lines = 20)
        return [] unless File.exist?(log_path)

        File.readlines(log_path).last(lines).map(&:chomp)
      end

      # Render the launchd property list XML.
      # @param interval [Integer]
      # @param config [Worklog::Configuration]
      # @return [String]
      def self.plist_xml(interval: DEFAULT_INTERVAL, config: ::Worklog::Configuration.load)
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>#{xml_escape(LABEL)}</string>
            <key>ProgramArguments</key>
            <array>
              <string>#{xml_escape(ruby_path)}</string>
              <string>#{xml_escape(script_path)}</string>
              <string>sync</string>
            </array>
            <key>StartInterval</key>
            <integer>#{interval.to_i}</integer>
            <key>RunAtLoad</key>
            <true/>
            <key>StandardErrorPath</key>
            <string>#{xml_escape(err_path)}</string>
            <key>WorkingDirectory</key>
            <string>#{xml_escape(Dir.home)}</string>
            <key>ProcessType</key>
            <string>Background</string>
            <key>EnvironmentVariables</key>
            <dict>
          #{environment_xml(config)}
            </dict>
          </dict>
          </plist>
        XML
      end

      # Build the <key>/<string> pairs for EnvironmentVariables. Always exports a
      # PATH that includes the Ruby bindir; adds WORKLOG_DATABASE_URL on Postgres.
      # @param config [Worklog::Configuration]
      # @return [String]
      def self.environment_xml(config)
        vars = { 'PATH' => "#{File.dirname(ruby_path)}:/usr/bin:/bin:/usr/sbin:/sbin" }
        db_url = database_url(config)
        vars['WORKLOG_DATABASE_URL'] = db_url if db_url

        vars.map do |key, value|
          "    <key>#{xml_escape(key)}</key>\n    <string>#{xml_escape(value)}</string>"
        end.join("\n")
      end

      # Resolve the database URL to bake in when on the Postgres engine.
      # @param config [Worklog::Configuration]
      # @return [String, nil]
      def self.database_url(config)
        return nil unless config.storage_engine == :postgres

        ENV['WORKLOG_DATABASE_URL'] || config.postgres_url
      end

      # Reload the job: boot out any existing instance, then bootstrap the plist.
      # @return [void]
      # @raise [Thor::Error] when the bootstrap step fails.
      def self.reload!
        launchctl('bootout', service_target)
        return if launchctl('bootstrap', domain, plist_path)

        raise Thor::Error, "launchctl bootstrap failed for #{plist_path}"
      end

      # Run a launchctl subcommand quietly, forwarding all positional arguments.
      # @return [Boolean] true on exit status 0.
      def self.launchctl(*) = system('launchctl', *, out: File::NULL, err: File::NULL) || false

      # Minimal XML text-node escaping for interpolated paths/values.
      # @param value [Object]
      # @return [String]
      def self.xml_escape(value) = value.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
    end
  end
end
