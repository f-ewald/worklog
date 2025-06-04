# frozen_string_literal: true

require 'hash'

# DailyLog is a container for a day's work log.
class DailyLog
  # Container for a day's work log.
  include Hashify

  # Represents a single day's work log.
  attr_accessor :date, :entries

  def initialize(params = {})
    @date = params[:date]
    @entries = params[:entries]
  end

  def people?
    # Returns true if there are people mentioned in any entry of the current day.
    people.size.positive?
  end

  def people
    # Returns a hash of people mentioned in the log for the current day
    # with the number of times they are mentioned.
    # People are defined as words starting with @ or ~.
    #
    # @return [Hash<String, Integer>]
    entries.map(&:people).flatten.tally
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

  def ==(other)
    date == other.date && entries == other.entries
  end
end
