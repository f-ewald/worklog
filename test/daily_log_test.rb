# frozen_string_literal: true

require 'date'
require 'minitest/autorun'
require_relative '../worklog/daily_log'

class DailyLogTest < Minitest::Test
  def setup
    @log = DailyLog.new(Date.new(2021, 1, 1), [])
  end

  def test_date
    # Test that the date is correctly set.
    date = Date.new(2021, 1, 1)
    assert_equal date, @log.date
  end

  def test_entries
    assert_equal [], @log.entries
  end

  def test_equality
    log1 = DailyLog.new(Date.new(2021, 1, 1), [])
    log2 = DailyLog.new(Date.new(2021, 1, 1), [])
    log3 = DailyLog.new(Date.new(2021, 1, 2), [])

    assert_equal log1, log2
    refute_equal log1, log3
  end
end