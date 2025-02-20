# frozen_string_literal: true

require 'rainbow'
require 'time'
require_relative 'daily_log'
require_relative 'logger'

module Storage
  # LogNotFoundError is raised when a log file is not found
  class LogNotFoundError < StandardError; end
  class LogLoadError < StandardError; end

  FILE_SUFFIX = '.yaml'
  DATA_DIR = File.join(Dir.home, '.worklog')

  # Check if the data folder exists and return true if it does, false otherwise
  #
  # @return [Boolean] True if the data folder exists, false otherwise
  def self.folder_exists?
    Dir.exist?(DATA_DIR)
  end

  # Return all days with logs. If no logs exist, an empty array is returned.
  #
  # @return [Array] Array of DailyLog objects
  def self.all_days
    return [] unless folder_exists?

    logs = []
    Dir.glob(File.join(DATA_DIR, "*#{FILE_SUFFIX}")).map do |file|
      logs << load_log(file)
    end

    logs
  end

  # Search for logs with a given query
  #
  # @param [String] query The search query
  # @return [Array] Array of logs that match the query
  def self.search(query)
    # terms = query.split
    # all_days.
  end

  # Return days between start_date and end_date
  # If end_date is nil, return logs from start_date to today
  #
  # @param [Date] start_date The start date, inclusive
  # @param [Date] end_date The end date, inclusive
  # @param [Boolean] epics_only If true, only return logs with epic entries
  # @param [Array] tags_filter If provided, only return logs with entries that have at least one of the tags
  def self.days_between(start_date, end_date = nil, epics_only = nil, tags_filter = nil)
    return [] unless folder_exists?

    logs = []
    end_date = Date.today if end_date.nil?

    return [] if start_date > end_date

    while start_date <= end_date
      if File.exist?(filepath(start_date))
        tmp_logs = load_log(filepath(start_date))
        tmp_logs.entries.keep_if { |entry| entry.epic? } if epics_only

        if tags_filter
          # Safeguard against entries without any tags, not just empty array
          tmp_logs.entries.keep_if { |entry| entry.tags && (entry.tags & tags_filter).size > 0 }
        end

        logs << tmp_logs if tmp_logs.entries.length > 0
      end

      start_date += 1
    end
    logs
  end

  # Create file for a new day if it does not exist
  def self.create_file_skeleton(date)
    create_folder

    File.write(filepath(date), YAML.dump(DailyLog.new(date:, entries: []))) unless File.exist?(filepath(date))
  end

  # Delete a log file at the given path
  #
  # @param [String] file The file to delete
  def self.delete(file)
    File.delete(file) if File.exist?(file)
  end

  def self.load_log(file)
    load_log!(file)
  rescue LogNotFoundError
    WorkLogger.error "No work log found for #{file}. Aborting."
    nil
  end

  # Load log file or raise LogNotFoundError if file does not exist
  #
  # @param [String] file The file to load
  # @return [DailyLog] The loaded log
  # @raise [LogNotFoundError] If the file does not exist
  def self.load_log!(file)
    WorkLogger.debug "Loading file #{file}"
    begin
      log = YAML.load_file(file, permitted_classes: [Date, Time, DailyLog, LogEntry])

      # Older logs are saved as HH:MM:SS strings, convert to Time objects
      log.entries.each do |entry|
        Time.strptime(entry.time, '%H:%M:%S') if entry.time.is_a?(String)
      end
      log
    rescue Errno::ENOENT
      raise LogNotFoundError
    rescue NoMethodError
      raise LogLoadError, "Error loading log file #{file}."
    end
  end

  def self.write_log(file, daily_log)
    create_folder

    WorkLogger.debug "Writing to file #{file}"

    File.open(file, 'w') do |f|
      f.puts daily_log.to_yaml
    end
  end

  def self.load_single_log_file(file, headline = true)
    daily_log = load_log(file)
    puts "Work log for #{Rainbow(daily_log.date).gold}:" if headline
    daily_log.entries
  end

  private

  # Create folder if not exists already.
  def create_folder
    Dir.mkdir(DATA_DIR) unless Dir.exist?(DATA_DIR)
  end

  def filepath(date)
    # Construct filepath for a given date.
    File.join(DATA_DIR, "#{date}#{FILE_SUFFIX}")
  end

  module_function :create_folder, :filepath
end
