# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require 'storage/base'
require 'daily_log'
require 'log_entry'
require 'worklogger'

module Worklog
  module Storage
    # YAML-backed implementation of {Worklog::Storage::Base}. One file
    # per day under `config.storage_path`, named `YYYY-MM-DD.yaml`.
    class Yaml < Base
      FILE_SUFFIX = '.yaml'

      # Regular expression matching valid daily log file names.
      LOG_PATTERN = /\d{4}-\d{2}-\d{2}#{FILE_SUFFIX}\z/

      # @return [Boolean]
      def folder_exists?
        Dir.exist?(@config.storage_path)
      end

      # @return [Array<DailyLog>]
      def all_days
        return [] unless folder_exists?

        logs = []
        Dir.glob(File.join(@config.storage_path, "*#{FILE_SUFFIX}")).each do |file|
          next unless file.match?(LOG_PATTERN)

          log = load_log_from_path(file)
          logs << log if log
        end
        logs
      end

      # @param date [Date]
      # @return [DailyLog, nil]
      def load_log_for_date(date)
        path = filepath(date)
        return nil unless File.exist?(path)

        load_log_from_path(path)
      end

      # Persist the daily log to its YAML file. Entries are sorted by
      # time before writing.
      # @param daily_log [DailyLog]
      # @return [void]
      def save_log(daily_log)
        path = filepath(daily_log.date)
        WorkLogger.debug "Writing to file #{path}"
        File.open(path, 'w') do |f|
          daily_log.entries.sort_by!(&:time)
          f.puts daily_log.to_yaml
        end
      end

      # Write an empty skeleton file for a date if none exists.
      # @param date [Date]
      # @return [void]
      def ensure_log_for_date(date)
        return if File.exist?(filepath(date))

        File.write(filepath(date), YAML.dump(DailyLog.new(date:, entries: [])))
      end

      # Construct the absolute file path for a given date.
      # @param date [Date]
      # @return [String]
      def filepath(date)
        File.join(@config.storage_path, "#{date}#{FILE_SUFFIX}")
      end

      # Create the storage directory if it is the default path.
      # @return [void]
      def create_default_folder
        WorkLogger.debug 'Creating storage folder if it does not exist.'
        unless @config.default_storage_path?
          WorkLogger.debug 'Custom storage path detected, skipping creation of default storage folder.'
          return
        end

        FileUtils.mkdir_p(@config.storage_path)
      end

      private

      # Read and parse a single YAML log file by path.
      # @param file [String]
      # @return [DailyLog, nil]
      def load_log_from_path(file)
        WorkLogger.debug "Loading file #{file}"
        yaml_content = File.read(file)
        cleaned_yaml = yaml_content.gsub(%r{!ruby/object:[^\s]+}, '')
        log = DailyLog.from_hash(YAML.safe_load(cleaned_yaml, permitted_classes: [Date, Time], symbolize_names: true))
        log.entries.each do |entry|
          entry.time = Time.parse(entry.time) unless entry.time.respond_to?(:strftime)
        end
        log
      rescue Errno::ENOENT
        WorkLogger.error "No work log found for #{file}. Aborting."
        nil
      end
    end
  end
end
