# frozen_string_literal: true

# Add the current directory to the load path
# curr_dir = File.expand_path(__dir__)
# $LOAD_PATH << curr_dir unless $LOAD_PATH.include?(curr_dir)

require 'thor'
require 'date'
require 'worklogger'

require 'worklog'
require 'date_parser'
require 'configuration'
require 'editor'
require 'printer'
require 'statistics'
require 'storage'
require 'string_helper'
require 'summary'
require 'version'
require 'webserver'

# CLI for the work log application
class WorklogCLI < Thor
  attr_accessor :config, :storage

  include StringHelper
  class_option :verbose, type: :boolean, aliases: '-v', desc: 'Enable verbose output'

  package_name 'Worklog'

  # Initialize the CLI with the given arguments, options, and configuration
  def initialize(args = [], options = {}, config = {})
    @config = load_configuration
    @storage = Storage.new(@config)
    super
  end

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
    worklog = Worklog.new
    worklog.add(message, options)
  end

  desc 'edit', 'Edit a day in the work log. By default, the current date is used.'
  option :date, type: :string, default: DateTime.now.strftime('%Y-%m-%d')
  def edit
    worklog = Worklog.new
    worklog.edit(options)
  end

  desc 'remove', 'Remove last entry from the log'
  option :date, type: :string, default: DateTime.now.strftime('%Y-%m-%d')
  def remove
    worklog = Worklog.new
    worklog.remove(options)
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
    worklog = Worklog.new
    worklog.show(options)
  end

  desc 'people', 'Show all people mentioned in the work log'
  def people(person = nil)
    worklog = Worklog.new
    worklog.people(person, options)
  end

  desc 'tags', 'Show all tags used in the work log'
  def tags
    worklog = Worklog.new
    worklog.tags(options)
  end

  desc 'server', 'Start the work log server'
  def server
    app = WorkLogApp.new(@storage)
    WorkLogServer.new(app).start
  end

  desc 'stats', 'Show statistics for the work log'
  def stats
    worklog = Worklog.new
    worklog.stats(options)
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
    worklog = Worklog.new
    worklog.summary(options)
  end

  desc 'version', 'Show the version of the Worklog'
  def version
    puts "Worklog #{current_version} running on Ruby #{RUBY_VERSION}"
  end

  # Define shortcuts and aliases
  map 'a' => :add
  map 'statistics' => :stats
  map 'serve' => :server
end
