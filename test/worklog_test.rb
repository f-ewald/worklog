# frozen_string_literal: true

require_relative 'test_helper'
require 'log_entry'
require 'worklog'
require 'configuration'
require 'webserver'

class WorklogTest < Minitest::Test
  def setup
    @worklog = Worklog::Worklog.new(configuration_helper)
  end

  def test_initialize
    config = configuration_helper
    worklog = Worklog::Worklog.new(config)
    assert_instance_of Worklog::Worklog, worklog
    refute_nil worklog.config
    assert_equal config, worklog.config
  end

  def test_add
    # TODO: Create a stubbed project
    message = 'Worked on feature X'
    options = {
      date: '2023-09-01',
      time: '08:00:00',
      tags: ['development', 'feature-x'],
      ticket: 'TICKET-123',
      url: 'http://example.com/ticket/TICKET-123',
      epic: true,
      project: 'P001'
    }
    @worklog.stub :validate_projects!, nil do
      @worklog.add(message, options)
    end
    daily_log = @worklog.storage.load_log!(@worklog.storage.filepath(Date.parse(options[:date])))
    assert_instance_of LogEntry, daily_log.entries.last
    assert_equal message, daily_log.entries.last.message
    assert_equal options[:tags], daily_log.entries.last.tags
    assert_equal options[:ticket], daily_log.entries.last.ticket
    assert_equal options[:url], daily_log.entries.last.url
    assert_equal options[:epic], daily_log.entries.last.epic
    puts daily_log
    assert_equal options[:project], daily_log.entries.last.project
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

  def test_server
    mock = Minitest::Mock.new
    mock.expect :start, nil, []

    WorkLogServer.stub :new, ->(app) { mock } do
      @worklog.server
    end

    mock.verify
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

  def test_validate_projects
    # Test with no projects
    File.delete(File.join(@worklog.config.storage_path, Worklog::ProjectStorage::FILE_NAME)) if File.exist?(File.join(@worklog.config.storage_path, Worklog::ProjectStorage::FILE_NAME))

    assert_raises Worklog::ProjectNotFoundError do
      @worklog.validate_projects!('P001')
    end

    # Test with existing projects
    yaml_content = <<~YAML
      - key: P001
        name: Test Project
        description: A test project
        start_date: 2023-01-01
        end_date: 2023-12-31
        status: active
    YAML
    File.write(File.join(@worklog.config.storage_path, Worklog::ProjectStorage::FILE_NAME), yaml_content)

    assert_silent do
      @worklog.validate_projects!('P001')
    end
  end
end