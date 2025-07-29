# frozen_string_literal: true

require_relative 'test_helper'
require 'date'
require 'minitest/autorun'
require 'daily_log'
require 'log_entry'
require 'printer'

class PrinterTest < Minitest::Test
  def setup
    @printer = Printer.new
  end

  def test_no_entries
    start_date = Date.new(2020, 1, 1)
    end_date = Date.new(2020, 1, 10)
    @printer.no_entries(start_date, end_date)
    @printer.no_entries(start_date, start_date)
  end

  def test_print_entry
    daily_log = DailyLog.new(date: Date.new(2020, 1, 1), entries: [])
    entry = LogEntry.new(time: '12:00:00', message: 'Test message')
    Printer.new.print_entry(daily_log, entry, false)
    Printer.new.print_entry(daily_log, entry, true)
  end

  def test_print_day
    daily_log = DailyLog.new(date: Date.new(2020, 1, 1), entries: [
      LogEntry.new(time: '09:00:00', message: 'Morning work', epic: false, project: 'xyz'),
    ])
    @printer.print_day(daily_log, false, false, project: 'xyz')
  end
end
