# frozen_string_literal: true

require 'date'
require 'minitest/autorun'
require_relative 'test_helper'
require_relative '../worklog/worklog'
require_relative '../worklog/storage'
require_relative '../worklog/log_entry'

class StorageTest < Minitest::Test
  def setup
    @date = Date.new(2020, 1, 1)
    @time = Time.new(2020, 1, 1, 10, 0, 0)
    @daily_log = DailyLog.new(date: @date, entries: [LogEntry.new(time: @time, tags: ['tag1', 'tag2'], ticket: 'ticket-123', url: 'https://example.com/', epic: true, message: 'This is a message')])

    assert_instance_of Date, @date
    assert_instance_of Time, @time
    assert_instance_of DailyLog, @daily_log
    assert_instance_of LogEntry, @daily_log.entries.first
  end

  def test_all_days
    all_days = Storage.all_days
    assert_instance_of Array, all_days

    all_days.each do |daily_log|
      assert_instance_of DailyLog, daily_log
    end
  end

  def test_filepath
    filepath = Storage::filepath(@date)
    assert_instance_of String, filepath
    assert filepath.end_with?(".worklog/2020-01-01#{Storage::FILE_SUFFIX}")
  end

  def test_create_file_skeleton
    Storage::create_file_skeleton(@date)

    assert_path_exists Storage::filepath(@date)
  end

  def test_load_log
    Storage::write_log(Storage::filepath(@date), @daily_log)
    loaded_log = Storage::load_log(Storage::filepath(@date))

    assert_equal loaded_log, @daily_log
  end

  def test_load_log!
    Storage::write_log(Storage::filepath(@date), @daily_log)
    loaded_log = Storage::load_log!(Storage::filepath(@date))

    assert_equal loaded_log, @daily_log
  end

  def test_load_log_not_found
    not_found_date = Date.new(2020, 1, 2)
    assert_nil Storage::load_log(Storage::filepath(not_found_date))
  end

  def test_load_log_not_found_with_exception
    not_found_date = Date.new(2020, 1, 2)
    assert_raises(Storage::LogNotFoundError) do
      Storage.load_log!(Storage.filepath(not_found_date))
    end
  end

  def test_write_log
    Storage::write_log(Storage::filepath(@date), @daily_log)

    assert_equal @daily_log, Storage::load_log(Storage::filepath(@date))
  end

  def test_load_people
    people = Storage.load_people!
    assert_empty people
  end

  def test_write_people
    Storage.write_people!([])
  end
end
