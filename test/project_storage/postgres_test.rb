# frozen_string_literal: true

require 'date'
require 'minitest/autorun'
require_relative '../test_helper'
require 'project_storage'

class ProjectStoragePostgresTest < Minitest::Test
  include Worklog

  def setup
    @config = postgres_configuration_helper
    @storage = ProjectStorage.build(@config)
    @project = Project.from_hash(
      key: 'P001',
      name: 'Test',
      description: 'A test project',
      start_date: Date.new(2024, 1, 1),
      end_date: Date.new(2024, 12, 31),
      status: 'active',
      repositories: ['acme/widgets']
    )
  end

  def teardown
    teardown_postgres_configuration
  end

  def test_build_returns_postgres
    assert_instance_of ProjectStorage::Postgres, @storage
  end

  def test_load_projects_empty
    assert_empty(@storage.load_projects)
  end

  def test_write_and_load_round_trip
    @storage.write_projects!([@project])
    loaded = @storage.load_projects

    assert_equal 1, loaded.size

    p = loaded['P001']

    assert_equal 'Test', p.name
    assert_equal 'A test project', p.description
    assert_equal Date.new(2024, 1, 1), p.start_date
    assert_equal 'active', p.status
    assert_equal 1, p.repositories.size
    assert_equal 'acme', p.repositories.first.owner
    assert_equal 'widgets', p.repositories.first.name
  end

  def test_exist?
    refute @storage.exist?('P001')
    @storage.write_projects!([@project])

    assert @storage.exist?('P001')
    refute @storage.exist?('PXXX')
  end

  def test_find_by
    @storage.write_projects!([@project])
    found = @storage.find_by(status: 'active')

    assert_equal ['P001'], found.map(&:key)
  end

  def test_write_projects_rejects_nil
    assert_raises(ArgumentError) { @storage.write_projects!(nil) }
  end
end
