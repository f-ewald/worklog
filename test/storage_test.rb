# frozen_string_literal: true

require 'date'
require 'minitest/autorun'
require_relative 'test_helper'
require 'worklog'
require 'person'
require 'storage'
require 'log_entry'

class StorageTest < Minitest::Test
  def setup
    @date = Date.new(2020, 1, 1)
    @time = Time.new(2020, 1, 1, 10, 0, 0)
    @daily_log = DailyLog.new(date: @date, entries: [LogEntry.new(time: @time, tags: ['tag1', 'tag2'], ticket: 'ticket-123', url: 'https://example.com/', epic: true, message: 'This is a message')])

    assert_instance_of Date, @date
    assert_instance_of Time, @time
    assert_instance_of DailyLog, @daily_log
    assert_instance_of LogEntry, @daily_log.entries.first

    @storage = Storage.new(configuration_helper)
    @storage.write_log(@storage.filepath(@date), @daily_log)
    @person_alex = Person.new('alex', 'Alex Test', 'alext@example.com', 'Team A', ['Note 1'])
    @person_laura = Person.new('laura', 'Laura Test', 'laurat@example.com', 'Team B', ['Note 2'])
    @storage.write_people!([@person_alex, @person_laura])
  end

  def test_all_days
    all_days = @storage.all_days
    assert_instance_of Array, all_days
    refute_empty all_days

    all_days.each do |daily_log|
      assert_instance_of DailyLog, daily_log
    end
  end

  def test_tags
    tags = @storage.tags
    assert_instance_of Set, tags
    assert tags.include?('tag1')
    assert tags.include?('tag2')
  end

  def test_filepath
    filepath = @storage.filepath(@date)
    assert_instance_of String, filepath
    assert filepath.end_with?("/2020-01-01#{Storage::FILE_SUFFIX}")
  end

  def test_create_file_skeleton
    @storage.create_file_skeleton(@date)

    assert_path_exists @storage.filepath(@date)
  end

  def test_load_log
    @storage.write_log(@storage.filepath(@date), @daily_log)
    loaded_log = @storage.load_log(@storage.filepath(@date))

    assert_equal loaded_log, @daily_log
  end

  def test_load_log!
    @storage.write_log(@storage.filepath(@date), @daily_log)
    loaded_log = @storage.load_log!(@storage.filepath(@date))

    assert_equal loaded_log, @daily_log
  end

  def test_load_log_not_found
    not_found_date = Date.new(2020, 1, 2)
    assert_nil @storage.load_log(@storage.filepath(not_found_date))
  end

  def test_load_log_not_found_with_exception
    not_found_date = Date.new(2020, 1, 2)
    assert_raises(Storage::LogNotFoundError) do
      @storage.load_log!(@storage.filepath(not_found_date))
    end
  end

  def test_write_log
    @storage.write_log(@storage.filepath(@date), @daily_log)

    assert_equal @daily_log, @storage.load_log(@storage.filepath(@date))
  end

  def test_load_people
    people = @storage.load_people!
    assert_equal [@person_alex, @person_laura], people
  end

  def test_load_people_hash
    people_hash = @storage.load_people_hash
    assert_instance_of Hash, people_hash
    assert_equal @person_alex, people_hash['alex']
    assert_equal @person_laura, people_hash['laura']
  end

  def test_log_pattern
    assert_match Storage::LOG_PATTERN, '2020-01-01.yaml'
    refute_match Storage::LOG_PATTERN, '2020-01-01.yml'
    refute_match Storage::LOG_PATTERN, '2020-01-01.txt'
    refute_match Storage::LOG_PATTERN, '2020-01-01'
    refute_match Storage::LOG_PATTERN, 'people.yaml'
    refute_match Storage::LOG_PATTERN, '2020-01-01-01.yaml'
    refute_match Storage::LOG_PATTERN, 'projects.yaml'
  end
end
