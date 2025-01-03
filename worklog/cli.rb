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

class WorklogCLI < Thor
  package_name 'Worklog'

  def self.exit_on_failure?
    true
  end

  desc 'add MESSAGE', 'Add a new entry to the work log, defaults to the current date.'
  long_desc <<-LONGDESC
  Add a new entry with the current date and time to the work log.
  The message is required and must be enclosed in quotes if it contains more than one word.
  LONGDESC
  option :date, type: :string, default: DateTime.now.strftime("%Y-%m-%d")
  option :time, type: :string, default: DateTime.now.strftime("%H:%M:%S")
  option :tags, type: :array, default: []
  option :ticket, type: :string
  option :epic, type: :boolean, default: false
  def add(message)
    date = Date.strptime(options[:date], '%Y-%m-%d')
    Storage::create_file_skeleton(date)

    daily_log = Storage::load_log(Storage::filepath(date))
    daily_log.entries << LogEntry.new(options[:time], options[:tags], options[:ticket], options[:epic], message)
    Storage::write_log(Storage::filepath(options[:date]), daily_log)
    logger.info Rainbow("Added to the work log for #{options[:date]}").green
  end

  desc 'remove', 'Remove last entry from the log'
  def remove
    logger.debug "Showing the work log for #{options[:date]}"
    unless File.exist?(filepath(options[:date]))
      logger.error Rainbow("No work log found for #{options[:date]}. Aborting.").red
      exit 1
    end

    # daily_log = load_log(filepath(options[:date]))
    # write_log
  end

  desc 'show', 'Show the work log for a specific date or a range of dates. Defaults to todays date.'
  long_desc <<-LONGDESC
  Show the work log for a specific date. Defaults to todays date.
  Use the --date option to specify a different date.
  Use the --from and --to options to specify a date range. Both dates are inclusive.
  LONGDESC
  option :date, type: :string, default: DateTime.now.strftime("%Y-%m-%d")
  option :from, type: :string, desc: <<-EOF
    'Inclusive start date of the range. Takes precedence over --date if defined.'
  EOF
  option :to, type: :string, desc: <<-EOF
    'Inclusive end date of the range. Takes precedence over --date if defined.'
  EOF
  option :days, type: :numeric, desc: <<-EOF
    'Number of days to show starting from --date. Takes precedence over --from and --to if defined.'
  EOF
  option :epics_only, type: :boolean, default: false
  option :tags, type: :array, default: []
  def show
    if options[:days]
      start_date = Date.today - options[:days]
      end_date = Date.today
    elsif options[:from]
      start_date = DateParser::parse_date_string!(options[:from], true)
      end_date = DateParser::parse_date_string!(options[:to], false) if options[:to]
    else
      start_date = Date.strptime(options[:date], '%Y-%m-%d')
      end_date = start_date
    end

    entries = Storage::days_between(start_date, end_date)
    entries.each do |entry|
      Printer::print_day(entry, entries.size > 1, options[:epics_only])
    end
  end

  desc 'tags', 'Show all tags used in the work log'
  def tags
    all_logs = Storage::all_days

    puts Rainbow("Tags used in the work log:").gold

    # Count all tags used in the work log
    tags = all_logs.map(&:entries).flatten.map(&:tags).flatten.compact.tally

    # Determine length of longest tag for formatting
    max_len = tags.keys.map(&:length).max

    tags.each { |k, v| puts "#{Rainbow(k.ljust(max_len)).gold}: #{v} occurrence(s)" }
  end

  desc 'server', 'Start the work log server'
  def server
    WorkLogServer.new.start
  end

  desc 'stats', 'Show statistics for the work log'
  def stats
    stats = Statistics::calculate
    puts "Total days: #{stats.total_days}"
    puts "Total entries: #{stats.total_entries}"
    puts "Total epics: #{stats.total_epics}"
    puts "Entries per day: #{'%.2f' % stats.avg_entries}"
    puts "First entry: #{stats.first_entry}"
    puts "Last entry: #{stats.last_entry}"
  end

  # Define shortcuts and aliases
  map 'a' => :add
  map 'statistics' => :stats
  map 'serve' => :server

  no_commands do
    def logger
      @logger ||= Logger.new(STDOUT, level: Logger::Severity::INFO)
    end
  end
end
WorklogCLI.start
