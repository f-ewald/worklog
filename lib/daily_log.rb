# frozen_string_literal: true

require 'hash'

module Worklog
  # DailyLog is a container for a day's work log.
  class DailyLog
    # Container for a day's work log.
    include Hashify

    # Represents a single day's work log.
    attr_accessor :date, :entries

    def initialize(params = {})
      @date = params[:date]
      @entries = params[:entries] || []
    end

    # Returns true if there are people mentioned in any entry of the current day.
    #
    # @return [Boolean] true if there are people mentioned, false otherwise.
    def people?
      people.size.positive?
    end

    # Returns a hash of people mentioned in the log for the current day
    # with the number of times they are mentioned.
    # People are defined as words starting with @ or ~.
    #
    # @return [Hash<String, Integer>]
    def people
      entries.map { |entry| entry.people.to_a }.flatten.tally
    end

    # Returns a sorted list of tags used in the entries for the current day.
    #
    # @return [Array<String>]
    #
    # @example
    #   log = DailyLog.new(date: Date.today,
    #                      entries: [LogEntry.new(message: "Work on something", tags: ['work', 'project'])])
    #   log.tags # => ["project", "work"]
    def tags
      entries.flat_map(&:tags).uniq.sort
    end

    # Create a DailyLog from a hash with symbolized keys
    #
    # @param hash [Hash] the hash to convert
    # @return [DailyLog] the created DailyLog object
    def self.from_hash(hash)
      new(
        date: hash[:date],
        entries: hash[:entries].map { |entry| LogEntry.from_hash(entry) }
      )
    end

    # Equals method to compare two DailyLog objects.
    #
    # @param other [DailyLog] the other DailyLog object to compare with
    # @return [Boolean] true if both DailyLog objects have the same date and entries, false otherwise
    def ==(other)
      date == other.date && entries == other.entries
    end

    # Access a log entry by its unique key.
    # To safeguard against multiple entries with the same key, and future-proofing,
    # an empty string will return nil.
    # @param key [String] the unique key of the log entry
    # @return [LogEntry, nil] the log entry with the specified key, or nil if not found
    def [](key)
      return nil if key.nil? || key.empty?

      @entries.find { |entry| entry.key == key }
    end

    # Add a log entry to the daily log in the entries array at the end.
    # At this point, the log is not checked for duplicates and not sorted.
    # @param entry [LogEntry] the log entry to add
    def <<(entry) = @entries << entry

    def size = @entries.size
    def length = @entries.length
    def empty? = @entries.empty?
    def clear = @entries.clear
    def key?(key) = @entries.any? { |entry| entry.key == key }
  end
end
