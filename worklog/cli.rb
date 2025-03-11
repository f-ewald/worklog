#!/usr/bin/env ruby
# frozen_string_literal: true

# Add the current directory to the load path
curr_dir = File.expand_path(__dir__)
$LOAD_PATH << curr_dir unless $LOAD_PATH.include?(curr_dir)

require 'thor'
require 'date'
require 'logger'

require 'date_parser'
require 'printer'
require 'statistics'
require 'storage'
require 'webserver'
require 'worklog'
require_relative 'summary'
require_relative 'editor'

# CLI for the work log application
class WorklogCLI < Thor
  class_option :verbose, type: :boolean, aliases: '-v', desc: 'Enable verbose output'

  package_name 'Worklog'

  def self.exit_on_failure?
    true
  end

  desc 'add MESSAGE', 'Add a new entry to the work log, defaults to the current date.'
  long_desc <<~LONGDESC
    Add a new entry with the current date and time to the work log.
    The message is required and must be enclosed in quotes if it contains more than one word.

    People can be referenced either by using the tilde "~" or the at symbol "@", followed by
    an alphanumeric string.
  LONGDESC
  option :date, type: :string, default: DateTime.now.strftime('%Y-%m-%d'), desc: 'Set the date of the entry'
  option :time, type: :string, default: DateTime.now.strftime('%H:%M:%S'), desc: 'Set the time of the entry'
  option :tags, type: :array, default: [], desc: 'Add tags to the entry'
  option :ticket, type: :string, desc: 'Ticket number associated with the entry. Can be any alphanumeric string.'
  option :url, type: :string, desc: 'URL to associate with the entry'
  option :epic, type: :boolean, default: false, desc: 'Mark the entry as an epic'
  def add(message)
    set_log_level

    # Remove leading and trailing whitespaces
    # Raise an error if the message is empty
    message = message.strip
    raise ArgumentError, 'Message cannot be empty' if message.empty?

    date = Date.strptime(options[:date], '%Y-%m-%d')
    time = Time.strptime(options[:time], '%H:%M:%S')
    Storage.create_file_skeleton(date)

    daily_log = Storage.load_log(Storage.filepath(date))
    daily_log.entries << LogEntry.new(time:, tags: options[:tags], ticket: options[:ticket], url: options[:url],
                                      epic: options[:epic], message:)

    # Sort by time in case an entry was added later out of order.
    daily_log.entries.sort_by!(&:time)

    Storage.write_log(Storage.filepath(options[:date]), daily_log)
    WorkLogger.info Rainbow("Added to the work log for #{options[:date]}").green
  end

  desc 'edit', 'Edit a specified day in the work log'
  option :date, type: :string, default: DateTime.now.strftime('%Y-%m-%d')
  def edit
    set_log_level

    date = Date.strptime(options[:date], '%Y-%m-%d')

    # Load existing log
    log = Storage.load_log(Storage.filepath(date))
    unless log
      WorkLogger.error "No work log found for #{options[:date]}. Aborting."
      exit 1
    end

    txt = Editor::EDITOR_PREAMBLE.result_with_hash(content: YAML.dump(log))
    return_val = Editor.open_editor(txt)

    Storage.write_log(Storage.filepath(date),
                      YAML.load(return_val, permitted_classes: [Date, Time, DailyLog, LogEntry]))
    WorkLogger.info Rainbow("Updated work log for #{options[:date]}").green
  end

  desc 'remove', 'Remove last entry from the log'
  option :date, type: :string, default: DateTime.now.strftime('%Y-%m-%d')
  def remove
    set_log_level

    date = Date.strptime(options[:date], '%Y-%m-%d')
    unless File.exist?(Storage.filepath(date))
      WorkLogger.error Rainbow("No work log found for #{options[:date]}. Aborting.").red
      exit 1
    end

    daily_log = Storage.load_log(Storage.filepath(options[:date]))
    if daily_log.entries.empty?
      WorkLogger.error Rainbow("No entries found for #{options[:date]}. Aborting.").red
      exit 1
    end

    removed_entry = daily_log.entries.pop
    Storage.write_log(Storage.filepath(date), daily_log)
    WorkLogger.info Rainbow("Removed entry: #{removed_entry.message}").green
  end

  desc 'show', 'Show the work log for a specific date or a range of dates. Defaults to todays date.'
  long_desc <<~LONGDESC
    Show the work log for a specific date or a range of dates. As a default, all items from the current day will be shown.
  LONGDESC
  option :date, type: :string, default: DateTime.now.strftime('%Y-%m-%d'),
                desc: <<~DESC
                  Show the work log for a specific date. If this option is provided, --from and --to and --days should not be used.
                DESC
  option :from, type: :string, desc: <<~EOF
    Inclusive start date of the range. Takes precedence over --date, if defined.
  EOF
  option :to, type: :string, desc: <<~EOF
    Inclusive end date of the range. Takes precedence over --date, if defined.
  EOF
  option :days, type: :numeric, desc: <<~EOF
    Number of days to show starting from --date. Takes precedence over --from and --to if defined.
  EOF
  option :epics_only, type: :boolean, default: false, desc: 'Show only entries that are marked as epic'
  option :tags, type: :array, default: [], desc: 'Filter entries by tags. Tags are treated as an OR condition.'
  def show
    set_log_level

    start_date, end_date = start_end_date(options)

    entries = Storage.days_between(start_date, end_date)
    if entries.empty?
      Printer.no_entries(start_date, end_date)
    else
      entries.each do |entry|
        Printer.print_day(entry, entries.size > 1, options[:epics_only])
      end
    end
  end

  desc 'people', 'Show all people mentioned in the work log'
  def people
    set_log_level

    puts 'People mentioned in the work log:'

    mentions = {}
    all_logs = Storage.all_days
    all_logs.map(&:people).each do |people|
      mentions.merge!(people) { |_key, oldval, newval| oldval + newval }
    end
    mentions.each { |k, v| puts "#{Rainbow(k).gold}: #{v} occurrence(s)" }
  end

  desc 'tags', 'Show all tags used in the work log'
  def tags
    set_log_level

    all_logs = Storage.all_days

    puts Rainbow('Tags used in the work log:').gold

    # Count all tags used in the work log
    tags = all_logs.map(&:entries).flatten.map(&:tags).flatten.compact.tally

    # Determine length of longest tag for formatting
    max_len = tags.keys.map(&:length).max

    tags.each { |k, v| puts "#{Rainbow(k.ljust(max_len)).gold}: #{v} occurrence(s)" }
  end

  desc 'server', 'Start the work log server'
  def server
    set_log_level

    WorkLogServer.new.start
  end

  desc 'stats', 'Show statistics for the work log'
  def stats
    stats = Statistics.calculate
    puts "#{format_left('Total days')}: #{stats.total_days}"
    puts "#{format_left('Total entries')}: #{stats.total_entries}"
    puts "#{format_left('Total epics')}: #{stats.total_epics}"
    puts "#{format_left('Entries per day')}: #{'%.2f' % stats.avg_entries}"
    puts "#{format_left('First entry')}: #{stats.first_entry}"
    puts "#{format_left('Last entry')}: #{stats.last_entry}"
  end

  desc 'summary', 'Generate a summary of the work log entries'
  option :date, type: :string, default: DateTime.now.strftime('%Y-%m-%d')
  option :from, type: :string, desc: <<-EOF
    'Inclusive start date of the range. Takes precedence over --date if defined.'
  EOF
  option :to, type: :string, desc: <<-EOF
    'Inclusive end date of the range. Takes precedence over --date if defined.'
  EOF
  option :days, type: :numeric, desc: <<-EOF
    'Number of days to show starting from --date. Takes precedence over --from and --to if defined.'
  EOF
  def summary
    set_log_level

    start_date, end_date = start_end_date(options)
    entries = Storage.days_between(start_date, end_date).map(&:entries).flatten

    # Do nothing if no entries are found.
    if entries.empty?
      Printer.no_entries(start_date, end_date)
      return
    end
    puts Summary.generate_summary(entries)
  end

  # Define shortcuts and aliases
  map 'a' => :add
  map 'statistics' => :stats
  map 'serve' => :server

  no_commands do
    def set_log_level
      # Set the log level based on the verbose option
      WorkLogger.level = options[:verbose] ? Logger::Severity::DEBUG : Logger::Severity::INFO
    end

    def format_left(string)
      # Format a string to be left-aligned in a fixed-width field
      #
      # @param string [String] the string to format
      # @return [String] the formatted string
      format('%18s', string)
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
      else
        start_date = Date.strptime(options[:date], '%Y-%m-%d')
        end_date = start_date
      end
      [start_date, end_date]
    end
  end
end

# Start the CLI if the file is executed
# This prevents the CLI from starting when the file is required in another file,
# which is useful for testing.
WorklogCLI.start if __FILE__ == $PROGRAM_NAME
