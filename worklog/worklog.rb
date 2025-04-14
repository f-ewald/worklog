#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'rainbow'
require 'yaml'

require_relative 'hash'
require_relative 'daily_log'
require_relative 'date_parser'
require_relative 'log_entry'
require_relative 'storage'
require_relative 'logger'
require_relative 'string_helper'
require_relative 'printer'
require_relative 'statistics'

# Main class providing all worklog functionality.
# This class is the main entry point for the application.
# It handles command line arguments, configuration, and logging.
class Worklog
  include StringHelper
  attr_reader :config

  def initialize(config = nil)
    @config = config || Configuration.new
    @storage = Storage.new(@config)

    WorkLogger.level = @config.log_level == :debug ? Logger::Severity::DEBUG : Logger::Severity::INFO
  end

  def add(message, options = {})
    # Remove leading and trailing whitespaces
    # Raise an error if the message is empty
    message = message.strip
    raise ArgumentError, 'Message cannot be empty' if message.empty?

    date = Date.strptime(options[:date], '%Y-%m-%d')
    time = Time.strptime(options[:time], '%H:%M:%S')
    @storage.create_file_skeleton(date)

    daily_log = @storage.load_log!(@storage.filepath(date))
    daily_log.entries << LogEntry.new(time:, tags: options[:tags], ticket: options[:ticket], url: options[:url],
                                      epic: options[:epic], message:)

    # Sort by time in case an entry was added later out of order.
    daily_log.entries.sort_by!(&:time)

    @storage.write_log(@storage.filepath(options[:date]), daily_log)

    WorkLogger.info Rainbow("Added entry on #{options[:date]}: #{message}").green
  end

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

  def show(options = {})
    people = @storage.load_people!
    printer = Printer.new(people)

    start_date, end_date = start_end_date(options)

    entries = @storage.days_between(start_date, end_date)
    if entries.empty?
      printer.no_entries(start_date, end_date)
    else
      entries.each do |entry|
        printer.print_day(entry, entries.size > 1, options[:epics_only])
      end
    end
  end

  def people(_options = {})
    puts 'People mentioned in the work log:'

    mentions = {}
    all_logs = @storage.all_days
    all_logs.map(&:people).each do |people|
      mentions.merge!(people) { |_key, oldval, newval| oldval + newval }
    end
    mentions.each { |k, v| puts "#{Rainbow(k).gold}: #{v} #{pluralize(v, 'occurrence')}" }
  end

  def tags(_options = {})
    all_logs = @storage.all_days

    puts Rainbow('Tags used in the work log:').gold

    # Count all tags used in the work log
    tags = all_logs.map(&:entries).flatten.map(&:tags).flatten.compact.tally

    # Determine length of longest tag for formatting
    # Add one additonal space for formatting
    max_len = tags.empty? ? 0 : tags.keys.map(&:length).max + 1

    tags.sort.each { |k, v| puts "#{Rainbow(k.ljust(max_len)).gold}: #{v} #{pluralize(v, 'occurrence')}" }
  end

  def stats(_options = {})
    stats = Statistics.new(@config).calculate
    puts "#{format_left('Total days')}: #{stats.total_days}"
    puts "#{format_left('Total entries')}: #{stats.total_entries}"
    puts "#{format_left('Total epics')}: #{stats.total_epics}"
    puts "#{format_left('Entries per day')}: #{'%.2f' % stats.avg_entries}"
    puts "#{format_left('First entry')}: #{stats.first_entry}"
    puts "#{format_left('Last entry')}: #{stats.last_entry}"
  end

  def summary(options = {})
    start_date, end_date = start_end_date(options)
    entries = @storage.days_between(start_date, end_date).map(&:entries).flatten

    # Do nothing if no entries are found.
    if entries.empty?
      Printer.new.no_entries(start_date, end_date)
      return
    end
    puts Summary.generate_summary(entries)
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
