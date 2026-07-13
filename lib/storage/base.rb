# frozen_string_literal: true

require 'date'
require 'daily_log'
require 'log_entry'
require 'worklogger'

module Worklog
  module Storage
    # LogNotFoundError is raised when a log for the requested date
    # does not exist in the backend.
    class LogNotFoundError < StandardError; end

    # Abstract base class for daily log storage backends. Concrete
    # backends (Yaml, Postgres) must implement {#all_days},
    # {#load_log_for_date}, and {#save_log}.
    class Base
      # @param config [Worklog::Configuration]
      def initialize(config)
        @config = config
      end

      # All daily logs known to the backend, in unspecified order.
      # @return [Array<DailyLog>]
      def all_days
        raise NotImplementedError
      end

      # Load the log for a given date. Returns nil when no log exists.
      # @param date [Date]
      # @return [DailyLog, nil]
      def load_log_for_date(_date)
        raise NotImplementedError
      end

      # Persist a daily log. The implementation is expected to upsert
      # by date and sort entries by time.
      # @param daily_log [DailyLog]
      # @return [void]
      def save_log(_daily_log)
        raise NotImplementedError
      end

      # Set of all tags ever used in any entry.
      # @return [Set<String>]
      def tags
        set = Set.new
        all_days.each do |log|
          log.entries.each do |entry|
            next unless entry.tags

            entry.tags.each { |tag| set << tag }
          end
        end
        set
      end

      # Logs for the inclusive date range, optionally filtered by
      # epic-only and tag membership.
      # @param start_date [Date]
      # @param end_date [Date, nil] defaults to today
      # @param epics_only [Boolean, nil]
      # @param tags_filter [Array<String>, nil]
      # @return [Array<DailyLog>]
      def days_between(start_date, end_date = nil, epics_only = nil, tags_filter = nil)
        end_date ||= Date.today
        return [] if start_date > end_date

        logs = []
        current = start_date
        while current <= end_date
          log = load_log_for_date(current)
          current += 1
          next if log.nil?

          log.entries = log.entries.select(&:epic?) if epics_only
          log.entries = log.entries.select { |entry| entry.tags&.intersect?(tags_filter) } if tags_filter
          logs << log unless log.entries.empty?
        end
        logs
      end

      # Load the log for a date, raising if it does not exist.
      # @param date [Date]
      # @return [DailyLog]
      # @raise [LogNotFoundError]
      def load_log_for_date!(date)
        load_log_for_date(date) || raise(LogNotFoundError, "No log found for #{date}")
      end

      # Test whether a log exists for the given date.
      # @param date [Date]
      # @return [Boolean]
      def log_exists?(date)
        !load_log_for_date(date).nil?
      end

      # Ensure there is a place to write the log for a date. For YAML
      # this writes an empty skeleton file; for Postgres this is a no-op
      # because rows are created on first save.
      # @param _date [Date]
      # @return [void]
      def ensure_log_for_date(_date); end

      # Create the storage directory layout (YAML only). Default no-op.
      # @return [void]
      def create_default_folder; end

      # Create default files like the configuration template. Default
      # implementation writes the configuration template if missing.
      # @return [void]
      def create_default_files
        WorkLogger.info 'Creating default files if they do not exist.'
        config_path = Configuration.config_file_path
        if File.exist?(config_path)
          WorkLogger.info "Configuration file (#{config_path}) already exists, skipping creation."
          return
        end

        WorkLogger.info "Creating default configuration file at #{config_path}."
        File.write(config_path, Configuration::CONFIGURATION_TEMPLATE.result)
      end
    end
  end
end
