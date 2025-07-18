#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'rainbow'
require 'yaml'

require 'hash'
require 'daily_log'
require 'date_parser'
require 'log_entry'
require 'storage'
require 'worklogger'
require 'string_helper'
require 'printer'
require 'statistics'
require 'summary'

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

  def people(person = nil, _options = {})
    all_people = @storage.load_people!
    people_map = all_people.to_h { |p| [p.handle, p] }
    all_logs = @storage.all_days

    if person
      unless people_map.key?(person)
        WorkLogger.error Rainbow("No person found with handle #{person}.").red
        return
      end
      person_detail(all_logs, all_people, people_map[person.strip])
    else
      puts 'People mentioned in the work log:'

      mentions = {}

      all_logs.map(&:people).each do |people|
        mentions.merge!(people) { |_key, oldval, newval| oldval + newval }
      end

      # Sort the mentions by handle
      mentions = mentions.to_a.sort_by { |handle, _| handle }

      mentions.each do |handle, v|
        if people_map.key?(handle)
          person = people_map[handle]
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
    printer = Printer.new(all_people)
    puts "All interactions with #{Rainbow(person.name).gold}"

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

  def tag_overview
    all_logs = @storage.all_days
    puts Rainbow('Tags used in the work log:').gold

    # Count all tags used in the work log
    tags = all_logs.map(&:entries).flatten.map(&:tags).flatten.compact.tally

    # Determine length of longest tag for formatting
    # Add one additonal space for formatting
    max_len = tags.empty? ? 0 : tags.keys.map(&:length).max + 1

    tags.sort.each { |k, v| puts "#{Rainbow(k.ljust(max_len)).gold}: #{v} #{pluralize(v, 'occurrence')}" }
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
    printer = Printer.new(@storage.load_people!)
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
      Printer.new.no_entries(start_date, end_date)
      return
    end
    puts Summary.new(@config).generate_summary(entries)
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
end
