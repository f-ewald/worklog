# frozen_string_literal: true

require_relative 'test_helper'
require 'worklog'
require 'configuration'

class WorklogTest < Minitest::Test
  def setup
    @config = Configuration.new do |cfg|
      cfg.storage_path = File.join(Dir.tmpdir, 'worklog_test')
      cfg.log_level = :debug
    end
    @worklog = Worklog.new(@config)
  end

  def test_initialize
    config = Configuration.new
    worklog = Worklog.new(config)
    assert_instance_of Worklog, worklog
    refute_nil worklog.config
  end

  def test_show
    @worklog.show(date: '2023-10-01')
  end

  def test_people
    @worklog.people
  end

  def test_people_interaction
    @worklog.people('person1')
  end

  def test_tags
    @worklog.tags
  end

  def test_tag_overview
    @worklog.tag_overview
  end

  def test_tag_detail
    @worklog.tag_detail('example_tag', {
      from: '2023-10-01',
      to: '2023-10-31'
    })
  end

  def test_stats
    @worklog.stats
  end

  def test_summary
    @worklog.summary(date: '2023-10-01')
  end

  def test_remove
    # TODO: Implement test for remove method
  end

  def test_start_end_date
    # Test days
    start_date, end_date = @worklog.start_end_date(days: 10)
    assert_equal Date.today - 10, start_date
    assert_equal Date.today, end_date

    # Test from and to
    start_date, end_date = @worklog.start_end_date(from: '2020-01-01', to: '2020-01-10')
    assert_equal Date.new(2020, 1, 1), start_date
    assert_equal Date.new(2020, 1, 10), end_date

    # Test date
    start_date, end_date = @worklog.start_end_date(date: '2020-01-01')
    assert_equal Date.new(2020, 1, 1), start_date
    assert_equal Date.new(2020, 1, 1), end_date

    # Test invalid days
    assert_raises ArgumentError do
      @worklog.start_end_date(days: -1)
    end

    start_date, end_date = @worklog.start_end_date(days: 0)
    assert_equal Date.today, start_date
    assert_equal Date.today, end_date

    assert_raises ArgumentError do
      @worklog.start_end_date
    end
  end
end