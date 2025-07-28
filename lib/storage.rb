# frozen_string_literal: true

require 'rainbow'
require 'daily_log'
require 'log_entry'
require 'worklogger'
require 'person'

# Handles storage of daily logs and people
class Storage
  # LogNotFoundError is raised when a log file is not found
  class LogNotFoundError < StandardError; end

  FILE_SUFFIX = '.yaml'

  # Regular expression to match daily log file names
  LOG_PATTERN = /\d{4}-\d{2}-\d{2}#{FILE_SUFFIX}\z/

  def initialize(config)
    @config = config
  end

  def folder_exists?
    Dir.exist?(@config.storage_path)
  end

  # Return all logs for all available days
  # @return [Array<DailyLog>] List of all logs
  def all_days
    return [] unless folder_exists?

    logs = []
    Dir.glob(File.join(@config.storage_path, "*#{FILE_SUFFIX}")).map do |file|
      next unless file.match?(LOG_PATTERN)

      logs << load_log(file)
    end

    logs
  end

  # Return all tags as a set
  # @return [Set<String>] Set of all tags
  def tags
    logs = all_days
    tags = Set[]
    logs.each do |log|
      log.entries.each do |entry|
        next unless entry.tags

        entry.tags.each do |tag|
          tags << tag
        end
      end
    end
    tags
  end

  # Return days between start_date and end_date
  # If end_date is nil, return logs from start_date to today
  #
  # @param [Date] start_date The start date, inclusive
  # @param [Date] end_date The end date, inclusive
  # @param [Boolean] epics_only If true, only return logs with epic entries
  # @param [Array<String>] tags_filter If provided, only return logs with entries that have at least one of the tags
  # @return [Array<DailyLog>] List of logs
  def days_between(start_date, end_date = nil, epics_only = nil, tags_filter = nil)
    return [] unless folder_exists?

    logs = []
    end_date = Date.today if end_date.nil?

    return [] if start_date > end_date

    while start_date <= end_date
      if File.exist?(filepath(start_date))
        tmp_logs = load_log!(filepath(start_date))
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
  # @param [Date] date The date, used as the file name.
  def create_file_skeleton(date)
    create_folder

    File.write(filepath(date), YAML.dump(DailyLog.new(date:, entries: []))) unless File.exist?(filepath(date))
  end

  def load_log(file)
    load_log!(file)
  rescue LogNotFoundError
    WorkLogger.error "No work log found for #{file}. Aborting."
    nil
  end

  def load_log!(file)
    WorkLogger.debug "Loading file #{file}"
    begin
      log = YAML.load_file(file, permitted_classes: [Date, Time, DailyLog, LogEntry])
      log.entries.each do |entry|
        entry.time = Time.parse(entry.time) unless entry.time.respond_to?(:strftime)
      end
      log
    rescue Errno::ENOENT
      raise LogNotFoundError
    end
  end

  def write_log(file, daily_log)
    create_folder

    WorkLogger.debug "Writing to file #{file}"

    File.open(file, 'w') do |f|
      f.puts daily_log.to_yaml
    end
  end

  def load_single_log_file(file, headline = true)
    daily_log = load_log!(file)
    puts "Work log for #{Rainbow(daily_log.date).gold}:" if headline
    daily_log.entries
  end

  # Load all people from the people file, or return an empty array if the file does not exist
  #
  # @return [Array<Person>] List of people
  def load_people
    load_people!
  rescue Errno::ENOENT
    WorkLogger.info 'Unable to load people.'
    []
  end

  # Load all people from the people file and return them as a hash with handle as key
  # @return [Hash<String, Person>] Hash of people with handle as key
  def load_people_hash
    load_people.to_h { |person| [person.handle, person] }
  end

  # Load all people from the people file
  # @return [Array<Person>] List of people
  def load_people!
    people_file = File.join(@config.storage_path, 'people.yaml')
    return [] unless File.exist?(people_file)

    YAML.load_file(people_file, permitted_classes: [Person])
  end

  # Write people to the people file
  # @param [Array<Person>] people List of people
  def write_people!(people)
    create_folder

    people_file = File.join(@config.storage_path, 'people.yaml')
    File.open(people_file, 'w') do |f|
      f.puts people.to_yaml
    end
  end

  # Create folder if not exists already.
  def create_folder
    Dir.mkdir(@config.storage_path) unless Dir.exist?(@config.storage_path)
  end

  # Construct filepath for a given date.
  # @param [Date] date The date
  # @return [String] The filepath
  def filepath(date)
    File.join(@config.storage_path, "#{date}#{FILE_SUFFIX}")
  end
end
