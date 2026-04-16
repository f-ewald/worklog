# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

require 'mcp_server'

# Shared setup for MCP tool and resource tests.
# Creates a temp storage directory with sample data and initializes McpContext.
module McpTestHelper
  # Set up McpContext with test configuration and sample data.
  # Call this from your test's setup method.
  def setup_mcp_context
    @config = configuration_helper
    @storage = Worklog::Storage.new(@config)
    @people_storage = Worklog::PeopleStorage.new(@config)
    @project_storage = Worklog::ProjectStorage.new(@config)

    write_sample_people
    write_sample_projects
    write_sample_logs

    Worklog::McpContext.config = @config
    Worklog::McpContext.storage = @storage
    Worklog::McpContext.people_storage = @people_storage
    Worklog::McpContext.project_storage = @project_storage
    Worklog::McpContext.people = @people_storage.load_people_hash
  end

  def teardown_mcp_context
    teardown_configuration
  end

  private

  def write_sample_people
    people_data = [
      { 'handle' => 'jdoe', 'name' => 'Jane Doe', 'team' => 'Platform', 'email' => 'jane@example.com' },
      { 'handle' => 'bob', 'name' => 'Bob Smith', 'team' => 'Frontend', 'inactive' => true }
    ]
    File.write(File.join(@config.storage_path, 'people.yaml'), people_data.to_yaml)
  end

  def write_sample_projects
    projects_data = [
      { 'key' => 'auth', 'name' => 'Auth Refactor', 'description' => 'Refactoring auth', 'status' => 'active',
        'start_date' => Date.new(2024, 1, 1) },
      { 'key' => 'docs', 'name' => 'Documentation', 'status' => 'completed' }
    ]
    File.write(File.join(@config.storage_path, 'projects.yaml'), projects_data.to_yaml)
  end

  def write_sample_logs
    # Day 1: 2024-03-15 - two entries, one epic
    log1 = Worklog::DailyLog.new(date: Date.new(2024, 3, 15), entries: [
      Worklog::LogEntry.new(
        key: 'abc1234', source: 'manual', time: Time.new(2024, 3, 15, 9, 0, 0),
        message: 'Reviewed PR for auth refactor with ~jdoe', tags: %w[code-review auth],
        epic: true, project: 'auth'
      ),
      Worklog::LogEntry.new(
        key: 'abc1235', source: 'github', time: Time.new(2024, 3, 15, 14, 0, 0),
        message: 'Fixed login bug', tags: ['bugfix'], ticket: 'AUTH-456',
        url: 'https://github.com/example/pr/1', project: 'auth'
      )
    ])
    @storage.write_log(@storage.filepath(Date.new(2024, 3, 15)), log1)

    # Day 2: 2024-03-16 - one entry with different project
    log2 = Worklog::DailyLog.new(date: Date.new(2024, 3, 16), entries: [
      Worklog::LogEntry.new(
        key: 'def5678', source: 'manual', time: Time.new(2024, 3, 16, 10, 0, 0),
        message: 'Updated API documentation with ~bob', tags: ['docs'],
        project: 'docs'
      )
    ])
    @storage.write_log(@storage.filepath(Date.new(2024, 3, 16)), log2)
  end
end
