# frozen_string_literal: true

require 'minitest/autorun'

require_relative 'test_helper'
require_relative '../worklog/cli'

class CliTest < Minitest::Test
  def setup
    @cli = WorklogCLI.new
  end

  def test_exit_on_failure
    assert WorklogCLI.exit_on_failure?
  end

  def test_set_log_level
    @cli.set_log_level
    assert_equal Logger::INFO, WorkLogger.level

    @cli.options = { verbose: true }
    @cli.set_log_level
    assert_equal Logger::DEBUG, WorkLogger.level
  end

  def test_format_left
    assert_equal '              test', @cli.format_left('test')
    assert_equal '                  ', @cli.format_left('')
    assert_equal '123456789012345678', @cli.format_left('123456789012345678')
    assert_equal '1234567890123456789', @cli.format_left('1234567890123456789')
  end

  def test_start_end_date
    # Test days
    start_date, end_date = @cli.start_end_date(days: 10)
    assert_equal Date.today - 10, start_date
    assert_equal Date.today, end_date

    # Test from and to
    start_date, end_date = @cli.start_end_date(from: '2020-01-01', to: '2020-01-10')
    assert_equal Date.new(2020, 1, 1), start_date
    assert_equal Date.new(2020, 1, 10), end_date

    # Test date
    start_date, end_date = @cli.start_end_date(date: '2020-01-01')
    assert_equal Date.new(2020, 1, 1), start_date
    assert_equal Date.new(2020, 1, 1), end_date

    # Test invalid days
    assert_raises ArgumentError do
      @cli.start_end_date(days: -1)
    end

    start_date, end_date = @cli.start_end_date(days: 0)
    assert_equal Date.today, start_date
    assert_equal Date.today, end_date
  end

  def test_show
    @cli.invoke(:show, [], verbose: true)
  end

  def test_show_days
    # out, _err = capture_io { @cli.invoke(:show, ['--days 10'], verbose: true) }
    # refute_match 'Number of days cannot be negative', out

    # out, _err = capture_io { @cli.invoke(:show, ['--days', '-1'], verbose: true) }
    # assert_match 'Number of days cannot be negative', out
  end

  def test_stats
    @cli.invoke(:stats, [], verbose: true)
  end

  def test_tags
    @cli.invoke(:tags, [], verbose: true)
  end
end
