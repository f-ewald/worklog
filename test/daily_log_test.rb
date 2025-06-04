# frozen_string_literal: true

require 'date'
require 'minitest/autorun'
require_relative 'test_helper'
require 'daily_log'
require 'log_entry'

class DailyLogTest < Minitest::Test
  def setup
    @log = DailyLog.new(date: Date.new(2021, 1, 1), entries: [])
  end

  def test_date
    # Test that the date is correctly set.
    date = Date.new(2021, 1, 1)

    assert_equal date, @log.date
  end

  def test_entries
    assert_empty @log.entries
  end

  def test_equality
    log1 = DailyLog.new(date: Date.new(2021, 1, 1), entries: [])
    log2 = DailyLog.new(date: Date.new(2021, 1, 1), entries: [])
    log3 = DailyLog.new(date: Date.new(2021, 1, 2), entries: [])

    assert_equal log1, log2
    refute_equal log1, log3
  end

  def test_people?
    # Test that the people? method returns true when there are people in the log.
    refute @log.people?
  end

  def test_people
    assert_empty @log.people

    @log.entries << LogEntry.new(message: "Hello, ~world!")
    _expected = { 'world' => 1 }
    assert_equal _expected, @log.people

    @log.entries << LogEntry.new(message: "Hello, ~world! ~person2 Hello, ~world!")
    _expected = { 'person2' => 1, 'world' => 2 }
    assert_equal _expected, @log.people
  end

  def test_tags
    # Test that the tags method returns an empty array when there are no entries.
    assert_empty @log.tags

    # Add an entry with tags and check if the tags are returned correctly.
    @log.entries << LogEntry.new(message: "Work on project", tags: ['work', 'project'])
    assert_equal ['work', 'project'], @log.tags

    # Add another entry with different tags and check if both tags are returned.
    @log.entries << LogEntry.new(message: "Meeting with team", tags: ['meeting', 'team'])
    assert_equal ['work', 'project', 'meeting', 'team'], @log.tags
  end
end
