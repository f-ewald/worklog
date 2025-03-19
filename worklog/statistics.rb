# frozen_string_literal: true

require 'date'
require 'storage'

STATS = Data.define(:total_days, :total_entries, :total_epics, :avg_entries, :first_entry, :last_entry)

# Module for calculating statistics for the work log.
module Statistics
  # Calculate statistics for the work log for all days.
  # @return [STATS] The statistics for the work log
  def self.calculate
    all_entries = Storage.all_days
    return STATS.new(0, 0, 0, 0, Date.today, Date.today) if all_entries.empty?

    total_days = all_entries.length
    total_entries = all_entries.sum { |entry| entry.entries.length }
    total_epics = all_entries.sum { |entry| entry.entries.select { |item| item.epic? }.length }
    avg_entries = total_entries.to_f / total_days
    min_day = all_entries.min_by { |entry| entry.date }.date
    max_day = all_entries.max_by { |entry| entry.date }.date

    STATS.new(
      total_days,
      total_entries,
      total_epics,
      avg_entries,
      min_day,
      max_day
    )
  end
end
