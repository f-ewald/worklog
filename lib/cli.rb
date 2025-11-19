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
    @config = Worklog::Configuration.load
    @storage = Worklog::Storage.new(@config)
    super
  end

  # Set the exit on failure behavior from Thor to true
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
  option :date, type: :string, default: Time.now.strftime('%Y-%m-%d'), desc: 'Set the date of the entry'
  option :time, type: :string, default: Time.now.strftime('%H:%M:%S'), desc: <<~DESC
    Set the time of the entry. Can be provided in HHMM, HH:MM, or HH:MM:SS format.
    By default, the system time zone is used and converted to UTC for storage.
  DESC
  option :tags, type: :array, default: [], desc: 'Add tags to the entry'
  option :ticket, type: :string, desc: 'Ticket number associated with the entry. Can be any alphanumeric string.'
  option :url, type: :string, desc: 'URL to associate with the entry'
  option :epic, type: :boolean, default: false, desc: 'Mark the entry as an epic'
  option :project, type: :string, desc: 'Key of the project. The project needs to be defined first.'
  def add(message)
    worklog = Worklog::Worklog.new
    worklog.add(message, options)
  end

  desc 'edit', 'Edit a day in the work log. By default, the current date is used.'
  option :date, type: :string, default: Time.now.strftime('%Y-%m-%d')
  def edit
    worklog = Worklog::Worklog.new
    worklog.edit(options)
  end

  desc 'remove', 'Remove last entry from the log'
  option :date, type: :string, default: Time.now.strftime('%Y-%m-%d')
  def remove
    worklog = Worklog::Worklog.new
    worklog.remove(options)
  end

  desc 'show', 'Show the work log for a specific date or a range of dates. Defaults to todays date.'
  long_desc <<~LONGDESC
    Show the work log for a specific date or a range of dates. As a default, all items from the current day will be shown.
  LONGDESC
  option :date, type: :string, default: Time.now.strftime('%Y-%m-%d'),
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
  option :project, type: :string, desc: 'Filter entries by project key.'
  def show
    worklog = Worklog::Worklog.new
    worklog.show(options)
  end

  desc 'people', 'Show all people mentioned in the work log'
  def people(person = nil)
    worklog = Worklog::Worklog.new
    worklog.people(person, options)
  end

  desc 'projects', 'Show all projects defined in the work log'
  option :oneline, type: :boolean, default: false, desc: 'Show only project titles and keys in a single line format'
  def projects
    worklog = Worklog::Worklog.new

    if options[:oneline]
      worklog.projects_oneline(options)
    else
      worklog.projects(options)
    end
  end

  desc 'tags', 'Show all tags used in the work log'
  option :date, type: :string, default: Time.now.strftime('%Y-%m-%d'),
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
  def tags(tag = nil)
    worklog = Worklog::Worklog.new
    worklog.tags(tag, options)
  end

  desc 'takeout', <<~EOF
    Export all work log data as a tar.gz archive. The archive contains all log files and settings.
    The filename will be in the format worklog_takeout_YYYYMMDD_HHMMSS.tar.gz
  EOF
  def takeout
    worklog = Worklog::Worklog.new
    worklog.takeout
  end

  desc 'server', 'Start the work log server'
  def server
    worklog = Worklog::Worklog.new
    worklog.server
  end

  desc 'stats', 'Show statistics for the work log'
  def stats
    worklog = Worklog::Worklog.new
    worklog.stats(options)
  end

  desc 'summary', 'Generate a summary of the work log entries'
  option :date, type: :string, default: Time.now.strftime('%Y-%m-%d')
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
    worklog = Worklog::Worklog.new
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
  map 'project' => :projects
end
