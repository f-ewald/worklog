# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require 'people_storage'

class PeopleStoragePostgresTest < Minitest::Test
  include Worklog

  def setup
    @config = postgres_configuration_helper
    @storage = PeopleStorage.build(@config)
    @alex = Person.new(handle: 'alex', name: 'Alex Test', github_username: 'alextest',
                       email: 'alex@example.com', team: 'A', notes: %w[note1 note2])
    @laura = Person.new(handle: 'laura', name: 'Laura Test', github_username: 'lauratest',
                        email: 'laura@example.com', team: 'B')
  end

  def teardown
    teardown_postgres_configuration
  end

  def test_build_returns_postgres
    assert_instance_of PeopleStorage::Postgres, @storage
  end

  def test_load_people_empty
    assert_empty @storage.load_people
  end

  def test_write_and_load_round_trip
    @storage.write_people!([@alex, @laura])
    loaded = @storage.load_people

    assert_equal 2, loaded.size
    assert_equal 'alex', loaded.first.handle
    assert_equal %w[note1 note2], loaded.first.notes
  end

  def test_find_by_handle
    @storage.write_people!([@alex, @laura])

    assert_equal 'Alex Test', @storage.find_by_handle('alex').name
    assert_nil @storage.find_by_handle('nope')
  end

  def test_find_by_github_username
    @storage.write_people!([@alex, @laura])

    assert_equal 'Laura Test', @storage.find_by_github_username('lauratest').name
    assert_nil @storage.find_by_github_username('nope')
  end

  def test_write_people_rejects_nil
    assert_raises(ArgumentError) { @storage.write_people!(nil) }
  end

  def test_write_people_rejects_non_array
    assert_raises(ArgumentError) { @storage.write_people!('nope') }
  end

  def test_write_people_replaces_existing_rows
    @storage.write_people!([@alex, @laura])
    @storage.write_people!([@alex])

    assert_equal 1, @storage.load_people.size
  end
end
