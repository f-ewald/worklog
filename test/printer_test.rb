# frozen_string_literal: true

require 'date'
require 'minitest/autorun'
require 'daily_log'
require 'log_entry'
require 'printer'

class PrinterTest < Minitest::Test
  def test_no_entries
    start_date = Date.new(2020, 1, 1)
    end_date = Date.new(2020, 1, 10)
    Printer.new.no_entries(start_date, end_date)
    Printer.new.no_entries(start_date, start_date)
  end

  def test_print_entry
    daily_log = DailyLog.new(date: Date.new(2020, 1, 1), entries: [])
    entry = LogEntry.new(time: '12:00:00', message: 'Test message')
    Printer.new.print_entry(daily_log, entry, false)
    Printer.new.print_entry(daily_log, entry, true)
  end
end
