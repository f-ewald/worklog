#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'rainbow'
require 'yaml'

require 'configuration'
require 'daily_log'
require 'date_parser'
require 'github/client'
require 'hash'
require 'hasher'
require 'log_entry'
require 'worklogger'
require 'string_helper'
require 'printer'
require 'project_storage'
require 'statistics'
require 'storage'
require 'summary'
require 'takeout'

module Worklog
  # Main class providing all worklog functionality.
  # This class is the main entry point for the application.
  # It handles command line arguments, configuration, and logging.
  # @!attribute [r] config
  #   @return [Configuration] The configuration object containing settings for the application.
  # @!attribute [r] storage
  #   @return [Storage] The storage object for managing file operations.
  #
  # @see Configuration
  # @see Storage
  # @see ProjectStorage
  #
  # @example
  #   worklog = Worklog.new
  #   worklog.add('Worked on feature X',
  #                date: '2023-10-01',
  #                time: '10:00:00',
  #                tags: ['feature', 'x'],
  #                ticket: 'TICKET-123')
  class Worklog
    include StringHelper

    attr_reader :config, :storage

    def initialize(config = nil)
      # Load or use provided configuration
      @config = config || Configuration.load

      # Initialize storage
      @storage = Storage.new(@config)

      WorkLogger.level = @config.log_level == :debug ? Logger::Severity::DEBUG : Logger::Severity::INFO

      bootstrap
    end

    # Bootstrap the worklog application.
    def bootstrap
      @storage.create_default_folder

      # Load all people as they're used in multiple/most of the methods.
      @people = @storage.load_people_hash
    end

    # Add new entry to the work log.
    # @param message [String] the message to add to the work log. This cannot be empty.
    # @param options [Hash] the options hash containing date, time, tags, ticket, url, epic, and project.
    # @raise [ArgumentError] if the message is empty.
    #
    # @example
    #   worklog.add('Worked on feature X', date: '2023-10-01', time: '10:00:00', tags: ['feature', 'x'], ticket:
    #   'TICKET-123', url: 'https://example.com/', epic: true, project: 'my_project')
    #
    # @return [void]
    def add(message, options = {})
      # Remove leading and trailing whitespaces
      # Raise an error if the message is empty
      message = message.strip
      raise ArgumentError, 'Message cannot be empty' if message.empty?

      date = Date.strptime(options[:date], '%Y-%m-%d')

      # Append seconds to time if not provided
      time = parse_time_string!(options[:time])
      @storage.create_file_skeleton(date)

      # Validate that the project exists if provided
      validate_projects!(options[:project]) if options[:project] && !options[:project].empty?

      # Use the first 7 characters of the SHA256 hash of message as the key
      key = Hasher.sha256(message)

      daily_log = @storage.load_log!(@storage.filepath(date))
      new_entry = LogEntry.new(key:, source: 'manual', time:, tags: options[:tags], ticket: options[:ticket],
                               url: options[:url], epic: options[:epic], message:, project: options[:project])
      daily_log << new_entry

      @storage.write_log(@storage.filepath(options[:date]), daily_log)

      (new_entry.people - @people.keys).each do |handle|
        WorkLogger.warn "Person with handle #{handle} not found. Consider adding them to people.yaml"
      end

      WorkLogger.info Rainbow("Added entry on #{options[:date]}: #{message}").green
    end

    # Edit an existing work log entry for a specific date.
    def edit(options = {})
      date = Date.strptime(options[:date], '%Y-%m-%d')

      # Load existing log
      log = @storage.load_log(@storage.filepath(date))
      unless log
        WorkLogger.error "No work log found for #{options[:date]}. Aborting."
        exit 1
      end

      txt = Editor::EDITOR_PREAMBLE.result_with_hash(content: YAML.dump(log))
      return_val = Editor.open_editor(txt)

      @storage.write_log(@storage.filepath(date),
                         YAML.load(return_val, permitted_classes: [Date, Time, DailyLog, LogEntry]))
      WorkLogger.info Rainbow("Updated work log for #{options[:date]}").green
    end

    # Show the work log for a specific date range or a single date.
    #
    # @param options [Hash] the options hash containing date range or single date.
    # @option options [Integer] :days the number of days to show from today (default: 1).
    # @option options [String] :from the start date in 'YYYY-MM-DD' format.
    # @option options [String] :to the end date in 'YYYY-MM-DD' format.
    # @option options [String] :date a specific date in 'YYYY-MM-DD' format.
    # @option options [Boolean] :epics_only whether to show only entries with epics (default: false).
    # @option options [String] :project the project key to filter entries by project.
    #
    # @example
    #   worklog.show(days: 7)
    #   worklog.show(from: '2023-10-01', to: '2023-10-31')
    #   worklog.show(date: '2023-10-01')
    def show(options = {})
      printer = Printer.new(@config, @people)

      start_date, end_date = start_end_date(options)

      entries = @storage.days_between(start_date, end_date)
      if entries.empty?
        printer.no_entries(start_date, end_date)
      else
        entries.each do |entry|
          printer.print_day(entry, entries.size > 1, options[:epics_only], project: options[:project])
        end
      end
    end

    # Show all known people and details about a specific person.
    def people(person = nil, options = {})
      all_logs = @storage.all_days

      if person
        unless @people.key?(person)
          WorkLogger.error Rainbow("No person found with handle #{person}.").red
          return
        end
        person_detail(all_logs, @people, @people[person.strip])
      else
        puts 'People mentioned in the work log:'

        mentions = {}

        all_logs.map(&:people).each do |people|
          mentions.merge!(people) { |_key, oldval, newval| oldval + newval }
        end

        # Sort the mentions by handle
        mentions = mentions.to_a.sort_by { |handle, _| handle }

        mentions.each do |handle, v|
          if @people.key?(handle)
            next unless @people[handle].active? || options[:inactive]

            person = @people[handle]
            print "#{Rainbow(person.name).gold} (#{handle})"
            print " (#{person.team})" if person.team
          else
            print handle
          end
          puts ": #{v} #{pluralize(v, 'occurrence')}"
        end
      end
    end

    def person_detail(all_logs, all_people, person)
      printer = Printer.new(@config, all_people)
      puts "All interactions with #{Rainbow(person.name).gold}"

      puts "GitHub: #{Rainbow(person.github_username).blue}" if person.github_username

      if person.notes
        puts 'Notes:'
        person.notes.each do |note|
          puts "* #{note}"
        end
      end

      puts 'Interactions:'
      all_logs.each do |daily_log|
        daily_log.entries.each do |entry|
          printer.print_entry(daily_log, entry, true) if entry.people.include?(person.handle)
        end
      end
    end

    # Show all projects, one line per project.
    # This is a compact view showing only project names and keys.
    def projects_oneline(_options = {})
      project_storage = ProjectStorage.new(@config)
      projects = project_storage.load_projects

      # Find longest project name for formatting
      max_len = projects.values.map { |p| p.name.length }.max || 0

      projects.each_value do |project|
        puts "#{Rainbow(project.name.ljust(max_len)).gold} #{project.key}"
      end
    end

    # Show all projects with details and recent activity.
    # This method loads all projects and their associated log entries.
    # It also calculates the last activity date for each project based on log entries.
    def projects(_options = {})
      project_storage = ProjectStorage.new(@config)
      projects = project_storage.load_projects

      # Load all entries to find latest activity for each project
      @storage.all_days.each do |daily_log|
        daily_log.entries.each do |entry|
          if projects.key?(entry.project)
            project = projects[entry.project]
            project.entries ||= []
            project.entries << entry
            # Update last activity date if entry time is more recent
            project.last_activity = entry.time if project.last_activity.nil? || entry.time > project.last_activity
          else
            WorkLogger.debug "Project with key '#{entry.project}' not found in projects. Skipping."
          end
        end
      end
      print_projects(projects)
    end

    def print_projects(projects)
      puts Rainbow('Active Projects:').gold
      projects.each_value do |project|
        # Sort entries by descending time
        project.entries.sort_by!(&:time).reverse!

        puts "#{Rainbow(project.name).gold} (#{project.key})"
        puts "  Description: #{project.description}" if project.description
        puts "  Start date: #{project.start_date.strftime('%b %d, %Y')}" if project.start_date
        puts "  End date: #{project.end_date.strftime('%b %d, %Y')}" if project.end_date
        puts "  Status: #{project.status}" if project.status
        puts "  Last activity: #{project.last_activity.strftime('%b %d, %Y')}" if project.last_activity
        puts "  #{project.activity_graph}"

        next unless project.entries && !project.entries.empty?

        puts "  Last #{[project.entries&.size, 3].min} entries:"
        puts "    #{project.entries.last(3).map do |e|
          "#{e.time.strftime('%b %d, %Y')} #{e.message_string(@people)}"
        end.join("\n    ")}"
      end
      puts 'No projects found.' if projects.empty?
    end

    # Show all tags used in the work log or details for a specific tag
    #
    # @param tag [String, nil] the tag to show details for, or nil to show all tags
    # @param options [Hash] the options hash containing date range
    # @return [void]
    #
    # @example
    #   worklog.tags('example_tag', from: '2023-10-01', to: '2023-10-31')
    #   worklog.tags(nil) # Show all tags for all time
    def tags(tag = nil, options = {})
      if tag.nil? || tag.empty?
        tag_overview
      else
        tag_detail(tag, options)
      end
    end

    # Export all work log data as a tar.gz archive.
    # The archive contains all log files and settings.
    # The filename will be in the format worklog_takeout_YYYYMMDD_HHMMSS.tar.gz
    def takeout
      takeout = Takeout.new(@config)
      tar_gz_data = takeout.to_tar_gz

      filename = "worklog_takeout_#{Time.now.strftime('%Y%m%d_%H%M%S')}.tar.gz"
      File.binwrite(filename, tar_gz_data)

      WorkLogger.info Rainbow("Created takeout archive: #{filename}").green

      # Return filename for further processing if needed
      filename
    end

    # Show overview of all tags used in the work log including their count.
    def tag_overview
      all_logs = @storage.all_days
      puts Rainbow('Tags used in the work log:').gold

      # Count all tags used in the work log
      tags = all_logs.map(&:entries).flatten.map(&:tags).flatten.compact.tally

      # Calculate the maximum count for scaling the output if needed
      max_count = tags.values.max || 0
      factor = 32.0 / max_count # Scale to a maximum of 32 characters wide

      # Calculate longest number length for formatting
      num_length = max_count.to_s.length

      # Determine length of longest tag for formatting
      # Add one additional space for formatting
      max_len = tags.empty? ? 0 : tags.keys.map(&:length).max + 1

      tags.sort.each do |k, v|
        print "#{Rainbow(k.to_s.rjust(max_len)).gold}: #{v.to_s.rjust(num_length)} "
        puts '#' * (v * factor).ceil
      end
    end

    # Show detailed information about a specific tag
    #
    # @param tag [String] the tag to show details for
    # @param options [Hash] the options hash containing date range
    # @return [void]
    #
    # @example
    #   worklog.tag_detail('example_tag', from: '2023-10-01', to: '2023-10-31')
    def tag_detail(tag, options)
      printer = Printer.new(@config, @people)
      start_date, end_date = start_end_date(options)

      @storage.days_between(start_date, end_date).each do |daily_log|
        next unless daily_log.tags.include?(tag)

        daily_log.entries.each do |entry|
          next unless entry.tags.include?(tag)

          printer.print_entry(daily_log, entry, true)
        end
      end
    end

    def stats(_options = {})
      stats = Statistics.new(@config).calculate
      puts "#{format_left('Total days')}: #{stats.total_days}"
      puts "#{format_left('Total entries')}: #{stats.total_entries}"
      puts "#{format_left('Total epics')}: #{stats.total_epics}"
      puts "#{format_left('Entries per day')}: #{format('%.2f', stats.avg_entries)}"
      puts "#{format_left('First entry')}: #{stats.first_entry}"
      puts "#{format_left('Last entry')}: #{stats.last_entry}"
    end

    def summary(options = {})
      start_date, end_date = start_end_date(options)
      entries = @storage.days_between(start_date, end_date).map(&:entries).flatten

      # Do nothing if no entries are found.
      if entries.empty?
        Printer.new(@config).no_entries(start_date, end_date)
        return
      end

      # List all the epics
      epics = entries.filter(&:epic)
      puts Rainbow("Found #{epics.size} epics.").green if epics.any?
      epics.each do |entry|
        puts "#{entry.time.strftime('%b %d, %Y')} #{entry.message}"
      end

      # List all the tags and their count
      tags = entries.map(&:tags).flatten.compact.tally
      puts Rainbow("Found #{tags.size} tags.").green if tags.any?
      tags.each do |tag, count|
        print "#{tag} (#{count}x), "
      end
      puts '' if tags.any?

      # List all the people and their count
      people = entries.map(&:people).flatten.compact.tally.sort_by { |_, count| -count }.filter { |_, count| count > 1 }
      puts Rainbow("Found #{people.size} people.").green if people.any?
      people.each do |person, count|
        print "#{person} (#{count}x), "
      end
      puts '' if people.any?

      # # Print the summary
      # summary = Summary.new(entries)
      # puts summary.to_s
    end

    def remove(options = {})
      date = Date.strptime(options[:date], '%Y-%m-%d')
      unless File.exist?(@storage.filepath(date))
        WorkLogger.error Rainbow("No work log found for #{options[:date]}. Aborting.").red
        exit 1
      end

      daily_log = @storage.load_log!(@storage.filepath(options[:date]))
      if daily_log.entries.empty?
        WorkLogger.error Rainbow("No entries found for #{options[:date]}. Aborting.").red
        exit 1
      end

      removed_entry = daily_log.entries.pop
      @storage.write_log(@storage.filepath(date), daily_log)
      WorkLogger.info Rainbow("Removed entry: #{removed_entry.message}").green
    end

    # Start webserver
    def server
      app = WorkLogApp.new(@storage)
      WorkLogServer.new(app).start
    end

    # Parse the start and end date based on the options provided
    #
    # @param options [Hash] the options hash
    # @return [Array] the start and end date as an array
    def start_end_date(options)
      if options[:days]
        # Safeguard against negative days
        raise ArgumentError, 'Number of days cannot be negative' if options[:days].negative?

        start_date = Date.today - options[:days]
        end_date = Date.today
      elsif options[:from]
        start_date = DateParser.parse_date_string!(options[:from], true)
        end_date = DateParser.parse_date_string!(options[:to], false) if options[:to]
      elsif options[:date]
        start_date = Date.strptime(options[:date], '%Y-%m-%d')
        end_date = start_date
      else
        raise ArgumentError, 'No date range specified. Use --days, --from, --to or --date options.'
      end
      [start_date, end_date]
    end

    # Validate that the project exists in the project storage if a project key is provided.
    #
    # @param project_key [String] the project key to validate
    # @raise [ProjectNotFoundError] if the project does not exist
    #
    # @return [void]
    #
    # @example
    #   validate_projects!('P001')
    def validate_projects!(project_key)
      project_storage = ProjectStorage.new(@config)
      begin
        projects = project_storage.load_projects
      rescue Errno::ENOENT
        raise ProjectNotFoundError, 'No projects found. Please create a project first.'
      end
      WorkLogger.debug "Project with key '#{project_key}' exists."
      return if projects.key?(project_key)

      raise ProjectNotFoundError, "Project with key '#{project_key}' does not exist."
    end

    # Parse a time string in HHMM, HH:MM, or HH:MM:SS format.
    # @param time_string [String] the time string to parse
    # @return [Time] the parsed Time object in UTC
    def parse_time_string!(time_string)
      # Validate the time string format
      unless time_string.match?(/^\d{1,2}:?\d{2}:?\d{2}?$/)
        raise ArgumentError, 'Invalid time format. Expected HHMM, HH:MM, or HH:MM:SS.'
      end

      # Prefix with 0 if needed
      time_string = "0#{time_string}" if time_string.length == 3

      # Split hours and minutes if in HHMM format
      if time_string.length == 4 && time_string.match?(/^\d{4}$/)
        time_string = "#{time_string[0..1]}:#{time_string[2..3]}"
      end

      # Append seconds to time if not provided
      time_string += ':00' if time_string.split(':').size == 2
      Time.strptime(time_string, '%H:%M:%S').utc
    end
  end
end
