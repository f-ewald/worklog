# frozen_string_literal: true

require 'rainbow'
require 'daily_log'
require 'log_entry'
require 'worklogger'
require 'person'

module Worklog
  # Handles storage of daily logs and people
  class Storage
    # LogNotFoundError is raised when a log file is not found
    class LogNotFoundError < StandardError; end

    FILE_SUFFIX = '.yaml'

    # Regular expression to match daily log file names
    LOG_PATTERN = /\d{4}-\d{2}-\d{2}#{FILE_SUFFIX}\z/

    # The template for the people YAML file.
    # This template is used to create a new people file if it does not exist.
    PERSON_TEMPLATE = <<~YAML
      ---
      # Each person is defined by the following attributes:
      # - handle: <unique_handle>
      #   github_username: <github_username>
      #   name: <full_name>
      #   team: <team_name>
      #   email: <email_address>
      #   role: <role_in_team>
      #   inactive: <true_or_false>
      #   --- Define your people below this line ---
    YAML

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
            tmp_logs.entries.keep_if { |entry| entry.tags&.intersect?(tags_filter) }
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
        yaml_content = File.read(file)
        cleaned_yaml = yaml_content.gsub(%r{!ruby/object:[^\s]+}, '')
        log = DailyLog.from_hash(YAML.safe_load(cleaned_yaml, permitted_classes: [Date, Time], symbolize_names: true))

        log.entries.each do |entry|
          entry.time = Time.parse(entry.time) unless entry.time.respond_to?(:strftime)
        end
        log
      rescue Errno::ENOENT
        raise LogNotFoundError
      end
    end

    def write_log(file, daily_log)
      WorkLogger.debug "Writing to file #{file}"

      File.open(file, 'w') do |f|
        # Sort entries by time before saving
        daily_log.entries.sort_by!(&:time)

        f.puts daily_log.to_yaml
      end
    end

    # Load a single log file and return its entries
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
      return [] unless File.exist?(people_filepath)

      yamltext = File.read(people_filepath)
      if yamltext != yamltext.gsub(/^- !.*$/, '-')
        WorkLogger.debug 'The people.yaml file contains deprecated syntax. Migrating now.'
        yamltext.gsub!(/^- !.*$/, '-')
        File.write(people_filepath, yamltext)
      end
      YAML.load(yamltext, permitted_classes: []).map { |person_hash| Person.from_hash(person_hash) }
    end

    # Write people to the people file
    # @param [Array<Person>] people List of people
    def write_people!(people)
      File.open(people_filepath, 'w') do |f|
        f.puts people.to_yaml
      end
    end

    # Create folder if not exists already.
    # @return [void]
    def create_default_folder
      WorkLogger.debug 'Creating storage folder if it does not exist.'

      # Do nothing if the storage path is not the default path
      unless @config.default_storage_path?
        WorkLogger.debug 'Custom storage path detected, skipping creation of default storage folder.'
        return
      end

      Dir.mkdir(@config.storage_path) unless Dir.exist?(@config.storage_path)
    end

    # This method assumes that the storage folder already exists.
    # It creates default files like people.yaml if they do not exist.
    def create_default_files
      WorkLogger.info 'Creating default files in storage folder if they do not exist.'
      # projects_file = File.join(@config.storage_path, 'projects.yaml')
      # unless File.exist?(projects_file)
      #   File.write(projects_file, [].to_yaml)
      # end

      if File.exist?(people_filepath)
        WorkLogger.info 'people.yaml already exists, skipping creation.'
      else
        WorkLogger.info 'Creating default people.yaml file.'
        File.write(people_filepath, PERSON_TEMPLATE)
      end

      # Write the default config file if it does not exist
      if File.exist?(Configuration.config_file_path)
        WorkLogger.info "Configuration file (#{Configuration.config_file_path}) already exists, skipping creation."
      else
        WorkLogger.info "Creating default configuration file at #{Configuration.config_file_path}."
        File.write(Configuration.config_file_path,
                   Configuration::CONFIGURATION_TEMPLATE.result)
      end

    end

    # Construct filepath for a given date.
    # @param [Date] date The date
    # @return [String] The filepath
    def filepath(date)
      File.join(@config.storage_path, "#{date}#{FILE_SUFFIX}")
    end

    # Return the full absolute filepath for the people.yaml file
    # @return [String] The filepath
    def people_filepath
      File.join(@config.storage_path, 'people.yaml')
    end
  end
end
