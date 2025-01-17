# frozen_string_literal: true

require "minitest/autorun"
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
end