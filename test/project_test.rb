# frozen_string_literal: true

require_relative 'test_helper'
require 'minitest/autorun'
require 'project'
require 'log_entry'

class ProjectTest < Minitest::Test
  include Worklog

  def setup
    @project = Project.new
    @project.key = 'PROJ'
    @project.name = 'Test Project'
    @project.description = 'A project for testing purposes'
    @project.start_date = Date.today - 10
    @project.end_date = Date.today + 10
    @project.status = 'active'
    @project.entries = []
    @project.repositories = [
      Github::Repository.from_url('https://github.com/owner/repository'),
      Github::Repository.from_url('https://github.com/owner/repo2')
    ]
  end

  def test_from_hash_missing_key
    assert_raises ArgumentError do
      Project.from_hash({})
    end

    assert_raises ArgumentError do
      Project.from_hash(nil)
    end
  end

  def test_started?
    assert @project.started?
    @project.start_date = Date.today + 1
    refute @project.started?

    @project.start_date = nil
    assert @project.started?
  end

  def test_ended?
    refute @project.ended?
    @project.end_date = Date.today - 1
    assert @project.ended?

    @project.end_date = nil
    refute @project.ended?
  end

  def test_from_hash
    project_data = {
      key: 'PROJ1',
      name: 'Test Project',
      description: 'A project for testing purposes',
      start_date: Date.new(2023, 1, 1),
      end_date: Date.new(2023, 12, 31),
      status: 'active',
      repositories: ['https://github.com/owner/repository', 'owner/repo2']
    }

    project = Project.from_hash(project_data)

    assert_instance_of Project, project
    assert_equal 'PROJ1', project.key
    assert_equal 'Test Project', project.name
    assert_equal 'A project for testing purposes', project.description
    assert_equal Date.new(2023, 1, 1), project.start_date
    assert_equal Date.new(2023, 12, 31), project.end_date
    assert_equal 'active', project.status
    assert_equal 2, project.repositories.size
    assert_instance_of Github::Repository, project.repositories.first
  end

  def test_project_metadata
    metadata = @project.project_metadata
    assert_includes metadata, 'Test Project'
    assert_includes metadata, 'PROJ'
    assert_includes metadata, 'A project for testing purposes'
    assert_includes metadata, 'active'
    assert_includes metadata, 'owner/repository'
    assert_includes metadata, 'owner/repo2'
  end

  def test_activity_graph
    # Add entries for the last 5 days
    (0..4).each do |i|
      entry = LogEntry.new
      entry.time = Time.now - i
      entry.message = "Work log entry #{i}"
      @project.entries << entry
    end

    graph = @project.activity_graph
    assert graph.is_a?(String)
    assert_includes graph, '#'
    assert_includes graph, '.'
    assert_includes graph, 'Today'
  end

  def test_contains_repository?
    assert @project.contains_repository?(Github::Repository.new(owner: 'owner', name: 'repository'))
    assert @project.contains_repository?(Github::Repository.new(owner: 'owner', name: 'repo2'))
    refute @project.contains_repository?(Github::Repository.new(owner: 'owner', name: 'unknown_repo'))
  end
end
