# frozen_string_literal: true

require_relative 'hash'

class DailyLog
  # Container for a day's work log.
  include Hashify

  # Represents a single day's work log.
  attr_accessor :date, :entries

  def initialize(params = {})
    @date = params[:date]
    @entries = params[:entries]
  end

  def ==(other)
    date == other.date && entries == other.entries
  end
end
