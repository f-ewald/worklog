# frozen_string_literal: true

require 'date'
require 'minitest/autorun'
require_relative 'test_helper'
require 'worklog'
require 'person'
require 'storage'
require 'log_entry'
require 'tzinfo'

class StorageTest < Minitest::Test
  include Worklog

  def setup
    @date = Date.new(2020, 1, 1)
    @time = Time.new(2020, 1, 1, 10, 0, 0)
    @daily_log = DailyLog.new(date: @date, entries: [LogEntry.new(time: @time, tags: ['tag1', 'tag2'], ticket: 'ticket-123', url: 'https://example.com/', epic: true, message: 'This is a message')])

    assert_instance_of Date, @date
    assert_instance_of Time, @time
    assert_instance_of DailyLog, @daily_log
    assert_instance_of LogEntry, @daily_log.entries.first

    @configuration = configuration_helper
    @storage = Storage.new(@configuration)
    @storage.write_log(@storage.filepath(@date), @daily_log)
    @person_alex = Person.new(handle: 'alex', name: 'Alex Test', email: 'alext@example.com', team: 'Team A', notes: ['Note 1'])
    @person_laura = Person.new(handle: 'laura', name: 'Laura Test', email: 'laurat@example.com', team: 'Team B', notes: ['Note 2'])
  end

  def teardown
    teardown_configuration
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
    @storage.write_people!([@person_alex, @person_laura])
    people = @storage.load_people!
    assert_equal [@person_alex, @person_laura], people
  end

  def test_load_people_hash
    @storage.write_people!([@person_alex, @person_laura])
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

  def test_store_sort_by_time
    unsorted_log = DailyLog.new(date: @date, entries: [
      LogEntry.new(time: Time.new(2020, 1, 1, 15, 0, 0), message: 'Afternoon work'),
      LogEntry.new(time: Time.new(2020, 1, 1, 9, 0, 0), message: 'Morning work'),
      LogEntry.new(time: Time.new(2020, 1, 1, 12, 0, 0), message: 'Noon work')
    ])

    @storage.write_log(@storage.filepath(@date), unsorted_log)
    loaded_log = @storage.load_log(@storage.filepath(@date))

    sorted_times = loaded_log.entries.map(&:time)
    assert_equal [Time.new(2020, 1, 1, 9, 0, 0), Time.new(2020, 1, 1, 12, 0, 0), Time.new(2020, 1, 1, 15, 0, 0)], sorted_times
  end

  def test_store_sort_by_time_with_timezone
    tz = TZInfo::Timezone.get('America/New_York')
    unsorted_log = DailyLog.new(date: @date, entries: [
      LogEntry.new(time: tz.local_time(2020, 1, 1, 15, 0, 0), message: 'Afternoon work'),
      LogEntry.new(time: tz.local_time(2020, 1, 1, 9, 0, 0), message: 'Morning work'),
      LogEntry.new(time: tz.local_time(2020, 1, 1, 12, 0, 0), message: 'Noon work')
    ])

    @storage.write_log(@storage.filepath(@date), unsorted_log)
    loaded_log = @storage.load_log(@storage.filepath(@date))

    sorted_times = loaded_log.entries.map(&:time)
    assert_equal [tz.local_time(2020, 1, 1, 9, 0, 0), tz.local_time(2020, 1, 1, 12, 0, 0), tz.local_time(2020, 1, 1, 15, 0, 0)], sorted_times
  end

  def test_store_sort_by_time_mixed_timezones
    tz_ny = TZInfo::Timezone.get('America/New_York')
    tz_la = TZInfo::Timezone.get('America/Los_Angeles')
    unsorted_log = DailyLog.new(date: @date, entries: [
      LogEntry.new(time: tz_ny.local_time(2020, 1, 1, 15, 0, 0), message: 'Afternoon work NY'),
      LogEntry.new(time: tz_la.local_time(2020, 1, 1, 9, 0, 0), message: 'Morning work LA'),
      LogEntry.new(time: tz_ny.local_time(2020, 1, 1, 12, 0, 0), message: 'Noon work NY')
    ])

    @storage.write_log(@storage.filepath(@date), unsorted_log)
    loaded_log = @storage.load_log(@storage.filepath(@date))

    sorted_times = loaded_log.entries.map(&:time)
    assert_equal [tz_la.local_time(2020, 1, 1, 9, 0, 0), tz_ny.local_time(2020, 1, 1, 12, 0, 0), tz_ny.local_time(2020, 1, 1, 15, 0, 0)], sorted_times
  end

  def test_store_sort_by_time_mixed_times
    tz_la = TZInfo::Timezone.get('America/Los_Angeles')
    unsorted_log = DailyLog.new(date: @date, entries: [
      LogEntry.new(time: Time.new(2020, 1, 1, 15, 0, 0, "UTC"), message: 'Afternoon work UTC'),
      LogEntry.new(time: tz_la.local_time(2020, 1, 1, 9, 0, 0), message: 'Morning work LA'),
      LogEntry.new(time: Time.new(2020, 1, 1, 12, 0, 0, "UTC"), message: 'Noon work UTC')
    ])

    @storage.write_log(@storage.filepath(@date), unsorted_log)
    loaded_log = @storage.load_log(@storage.filepath(@date))

    sorted_times = loaded_log.entries.map(&:time)
    assert_equal [
      Time.new(2020, 1, 1, 12, 0, 0, "UTC"),
      Time.new(2020, 1, 1, 15, 0, 0, "UTC"),
      tz_la.local_time(2020, 1, 1, 9, 0, 0)
      ], sorted_times
  end

  def test_people_filepath
    filepath = @storage.people_filepath
    assert_instance_of String, filepath
    assert filepath.end_with?('/people.yaml')
  end

  def test_create_default_people
    @storage.create_default_files

    assert_path_exists @storage.people_filepath
    assert_includes File.read(@storage.people_filepath), 'Each person is defined by the following attributes:'
  end

  def test_create_default_configuration
    Dir.mktmpdir do |dir|
      Dir.stub :home, dir do
        @storage.create_default_files

        config_file = File.join(dir, '.worklog.yaml')
        assert_path_exists config_file
        assert_includes File.read(config_file), 'storage_path:'
      end
    end
  end

  def test_create_default_projects
    skip "WIP: Implement ProjectStorage tests"
    @storage.create_default_files

    projects_file = File.join(@storage.config.storage_path, 'projects.yaml')
    assert_path_exists projects_file
    assert_equal [].to_yaml, File.read(projects_file)
  end
end
