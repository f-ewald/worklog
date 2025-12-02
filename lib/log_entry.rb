# frozen_string_literal: true

require 'yaml'
require 'rainbow'
require 'daily_log'
require 'hash'

module Worklog
  # A single log entry in a DailyLog.
  # @see DailyLog
  # @!attribute [rw] key
  #   @return [String] the unique key of the log entry. The key is generated based on the time and message.
  # @!attribute [rw] source
  #   @return [String] the source of the log entry, e.g., 'github', 'manual', etc.
  # @!attribute [rw] time
  #   @return [Time] the date and time of the log entry.
  # @!attribute [rw] tags
  #   @return [Array<String>] the tags associated with the log entry.
  # @!attribute [rw] ticket
  #   @return [String] the ticket associated with the log entry.
  # @!attribute [rw] url
  #   @return [String] the URL associated with the log entry.
  # @!attribute [rw] epic
  #   @return [Boolean] whether the log entry is an epic.
  # @!attribute [rw] message
  #   @return [String] the message of the log entry.
  # @!attribute [rw] project
  #   @return [String] the project associated with the log entry.
  class LogEntry
    PERSON_REGEX = /(?:\s|^)[~@](\w+)/

    include Hashify

    attr_accessor :key, :source, :time, :tags, :ticket, :url, :epic, :message, :project

    attr_reader :day

    def initialize(params = {})
      # key can be nil. This is needed for backwards compatibility with older log entries.
      @key = params[:key]
      @source = params[:source] || 'manual'
      @time = params[:time].is_a?(String) ? Time.parse(params[:time]) : params[:time]
      # If tags are nil, set to empty array.
      # This is similar to the CLI default value.
      @tags = params[:tags] || []
      @ticket = params[:ticket]
      @url = params[:url] || ''
      @epic = params[:epic]
      @message = params[:message]
      @project = params[:project]

      # Back reference to the day
      @day = params[:day] || nil
    end

    # Returns true if the entry is an epic, false otherwise.
    # @return [Boolean]
    def epic?
      @epic == true
    end

    # Returns the message string with formatting without the time.
    # @param known_people Hash[String, Person] A hash of people with their handles as keys.
    def message_string(known_people = nil)
      # replace all mentions of people with their names.
      msg = @message.dup
      people.each do |person|
        next unless known_people && known_people[person]

        msg.gsub!(/[~@]#{person}/) do |match|
          s = String.new
          s << ' ' if match[0] == ' '
          s << "#{Rainbow(known_people[person].name).underline} (~#{person})" if known_people && known_people[person]
          s
        end
      end

      s = String.new

      # Prefix with [EPIC] if epic
      s << epic_prefix if epic?

      # Print the message
      s << if source == 'github'
             Rainbow(msg).fg(:green)
           else
             msg
           end

      s << format_metadata
      s
    end

    def people
      # Return people that are mentioned in the entry. People are defined as character sequences
      # starting with @ or ~. Whitespaces are used to separate people. Punctuation is ignored.
      # Empty set if no people are mentioned.
      # @return [Set<String>]
      @message.scan(PERSON_REGEX).flatten.uniq.sort.to_set
    end

    # Return true if there are people in the entry.
    #
    # @return [Boolean]
    def people?
      people.size.positive?
    end

    # Create a LogEntry from a hash with symbolized keys
    # This is an alias for the constructor and here for consistency with other classes.
    #
    # @param hash [Hash] the hash to convert
    # @return [LogEntry] the created LogEntry object
    def self.from_hash(hash)
      new(**hash)
    end

    # Convert the log entry to YAML format.
    def to_yaml
      to_hash.to_yaml
    end

    # Compare two log entries for equality.
    #
    # @param other [LogEntry] The other log entry to compare against.
    # @return [Boolean] True if the log entries are equal, false otherwise.
    def ==(other)
      time == other.time && tags == other.tags && ticket == other.ticket && url == other.url &&
        epic == other.epic && message == other.message
    end

    private

    # Prefix for epic entries with formatting.
    # @return [String]
    def epic_prefix
      "#{Rainbow('[EPIC]').bg(:white).fg(:black)} "
    end

    # Format metadata for display.
    # @return [String]
    def format_metadata
      metadata_parts = []
      metadata_parts << Rainbow(@ticket).fg(:blue) if @ticket
      metadata_parts << @tags.join(', ') if @tags&.any?
      metadata_parts << @url if @url && @url != ''
      metadata_parts << @project if @project && @project != ''

      metadata_parts.empty? ? '' : "  [#{metadata_parts.join(']  [')}]"
    end
  end
end
