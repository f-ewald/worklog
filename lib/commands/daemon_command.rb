# frozen_string_literal: true

require 'fileutils'
require 'thor'

require 'configuration'
require 'worklogger'
require 'daemon/launch_agent'

module Worklog
  module Commands
    # Thor CLI for the `worklogd` background agent. Bare `worklogd` (or
    # `worklogd run`) performs one GitHub sync — the command launchd invokes
    # hourly — while install/uninstall/status manage the macOS LaunchAgent.
    # @see Worklog::Daemon::LaunchAgent
    class DaemonCommand < Thor
      def self.exit_on_failure? = true

      default_command :sync

      desc 'sync', 'Run the GitHub sync once (the command launchd invokes hourly).'
      long_desc <<~LONGDESC
        Acquire a single-instance lock, redirect logging to the rotating daemon
        log, and run the GitHub sync once. Transient failures (offline, missing
        token, GitHub 403) are logged and swallowed so launchd does not treat the
        run as a crash.
      LONGDESC
      def sync
        return unless acquire_lock!

        ::WorkLogger.log_to_file(::Worklog::Daemon::LaunchAgent.log_path)
        require 'worklog'
        ::Worklog::Worklog.new.github({})
      rescue SystemExit, StandardError => e
        # Includes `abort` from lib/db.rb. Log once and exit 0 (launchd retries next interval).
        ::WorkLogger.error("worklogd sync failed: #{e.class}: #{e.message}")
      end

      desc 'install', 'Install and load the hourly LaunchAgent (macOS).'
      long_desc <<~LONGDESC
        Write ~/Library/LaunchAgents/com.fewald.worklogd.plist and load it with
        launchctl. RunAtLoad triggers an immediate first sync. Re-run after a gem
        upgrade to refresh the interpreter path baked into the plist.
      LONGDESC
      option :interval, type: :numeric,
                        default: ::Worklog::Daemon::LaunchAgent::DEFAULT_INTERVAL,
                        desc: 'Seconds between syncs.'
      def install
        warn_if_unconfigured
        ::Worklog::Daemon::LaunchAgent.install!(interval: options[:interval].to_i)
        say "Installed #{::Worklog::Daemon::LaunchAgent::LABEL} (every #{options[:interval].to_i}s). " \
            "A first sync was triggered; logs: #{::Worklog::Daemon::LaunchAgent.log_path}"
      end

      desc 'uninstall', 'Unload and remove the LaunchAgent.'
      def uninstall
        ::Worklog::Daemon::LaunchAgent.uninstall!
        say "Removed #{::Worklog::Daemon::LaunchAgent::LABEL}."
      end

      desc 'status', 'Show whether the agent is loaded and tail recent logs.'
      def status
        loaded = ::Worklog::Daemon::LaunchAgent.loaded?
        say(loaded ? "worklogd: loaded (#{::Worklog::Daemon::LaunchAgent::LABEL})" : 'worklogd: not loaded')
        ::Worklog::Daemon::LaunchAgent.tail_log.each { |line| say line }
      end

      private

      # Acquire the non-blocking single-instance lock. The handle is held for the
      # process lifetime so the OS releases it on exit.
      # @return [File, nil] the held lock handle, or nil when another sync holds it.
      def acquire_lock!
        path = ::Worklog::Daemon::LaunchAgent.lock_path
        FileUtils.mkdir_p(File.dirname(path))
        lock = File.open(path, File::CREAT | File::RDWR)
        if lock.flock(File::LOCK_EX | File::LOCK_NB)
          @lock = lock
          return @lock
        end

        ::WorkLogger.info('Another worklogd sync is in progress; skipping.')
        nil
      end

      # Warn (without failing) when GitHub credentials are missing at install time.
      # @return [void]
      def warn_if_unconfigured
        key = ::Worklog::Configuration.load.github.api_key
        return unless key.nil? || key.empty?

        say('Warning: github.api_key is not set in ~/.worklog.yaml; syncs will no-op until configured.')
      end
    end
  end
end
