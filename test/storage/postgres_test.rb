# frozen_string_literal: true

require 'date'
require 'minitest/autorun'
require_relative '../test_helper'
require 'storage'

class StoragePostgresTest < Minitest::Test
  include Worklog

  def setup
    @config = postgres_configuration_helper
    @storage = Storage.build(@config)
    @date = Date.new(2024, 5, 1)
    @log = DailyLog.new(date: @date, entries: [
                          LogEntry.new(time: Time.new(2024, 5, 1, 9, 0, 0, 'UTC'), tags: %w[t1 t2],
                                       ticket: 'WL-1', url: 'https://example.com/', epic: true,
                                       message: 'morning', project: 'P1', key: 'abc')
                        ])
  end

  def teardown
    teardown_postgres_configuration
  end

  def test_build_returns_postgres
    assert_instance_of Storage::Postgres, @storage
  end

  def test_save_and_load_round_trip
    @storage.save_log(@log)
    loaded = @storage.load_log_for_date(@date)

    refute_nil loaded
    assert_equal @date, loaded.date
    assert_equal 1, loaded.entries.size

    entry = loaded.entries.first

    assert_equal 'morning', entry.message
    assert_equal %w[t1 t2], entry.tags
    assert_equal 'WL-1', entry.ticket
    assert_equal 'https://example.com/', entry.url
    assert entry.epic
    assert_equal 'P1', entry.project
  end

  def test_load_log_for_date_missing_returns_nil
    assert_nil @storage.load_log_for_date(Date.new(2099, 1, 1))
  end

  def test_load_log_for_date_bang_raises
    assert_raises(Storage::LogNotFoundError) do
      @storage.load_log_for_date!(Date.new(2099, 1, 1))
    end
  end

  def test_log_exists?
    refute @storage.log_exists?(@date)
    @storage.save_log(@log)

    assert @storage.log_exists?(@date)
  end

  def test_ensure_log_for_date_is_no_op
    @storage.ensure_log_for_date(@date)

    refute @storage.log_exists?(@date), 'Postgres ensure_log_for_date should not create rows'
  end

  def test_all_days
    @storage.save_log(@log)
    other = DailyLog.new(date: Date.new(2024, 5, 2),
                         entries: [LogEntry.new(time: Time.new(2024, 5, 2, 8), message: 'm', tags: [])])
    @storage.save_log(other)
    days = @storage.all_days

    assert_equal 2, days.size
    assert_equal [Date.new(2024, 5, 1), Date.new(2024, 5, 2)], days.map(&:date).sort
  end

  def test_tags
    @storage.save_log(@log)

    assert_equal Set.new(%w[t1 t2]), @storage.tags
  end

  def test_days_between
    @storage.save_log(@log)
    other_log = DailyLog.new(date: Date.new(2024, 6, 1),
                             entries: [LogEntry.new(time: Time.new(2024, 6, 1, 8), message: 'later', tags: [])])
    @storage.save_log(other_log)

    in_range = @storage.days_between(Date.new(2024, 4, 1), Date.new(2024, 5, 31))

    assert_equal 1, in_range.size
    assert_equal Date.new(2024, 5, 1), in_range.first.date
  end

  def test_save_log_upserts
    @storage.save_log(@log)
    @log.entries << LogEntry.new(time: Time.new(2024, 5, 1, 15), message: 'second', tags: [])
    @storage.save_log(@log)

    loaded = @storage.load_log_for_date(@date)

    assert_equal 2, loaded.entries.size
  end

  def test_save_log_sorts_entries_by_time
    unsorted = DailyLog.new(date: Date.new(2024, 7, 1), entries: [
                              LogEntry.new(time: Time.new(2024, 7, 1, 15), message: 'late', tags: []),
                              LogEntry.new(time: Time.new(2024, 7, 1, 9), message: 'early', tags: [])
                            ])
    @storage.save_log(unsorted)
    loaded = @storage.load_log_for_date(Date.new(2024, 7, 1))

    assert_equal %w[early late], loaded.entries.map(&:message)
  end
end
