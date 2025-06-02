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

  def ==(other)
    date == other.date && entries == other.entries
  end
end
