# frozen_string_literal: true

require_relative 'test_helper'
require 'minitest/autorun'
require 'people_storage'

class PeopleStorageTest < Minitest::Test
  include Worklog

  def setup
    @configuration = configuration_helper
    @people_storage = PeopleStorage.new(@configuration)
  end

  def teardown
    teardown_configuration
  end

  # Helper function to create an example people.yaml file
  def create_example_people_file
    people_file = @people_storage.people_filepath
    File.write(people_file, <<~YAML)
      ---
      - handle: alex
        github_username: alextest
        name: Alex Test
        team: Team A
        email: alex@example.com
        role: Developer
        inactive: false
      - handle: laura
        github_username: lauratest
        name: Laura Test
        team: Team B
        email: laura@example.com
        role: Manager
        inactive: false
    YAML
  end
  def test_load_people_hash
    create_example_people_file
    people_hash = @people_storage.load_people_hash
    assert_instance_of Hash, people_hash
    refute_empty people_hash
    assert_equal 2, people_hash.size
  end

  def test_load_people_raises_error_if_file_not_exists
    people_file = @people_storage.people_filepath
    File.delete(people_file) if File.exist?(people_file)

    assert_raises(Errno::ENOENT) do
      @people_storage.load_people!
    end

  end

  def test_people_filepath
    expected_path = File.join(@configuration.storage_path, PeopleStorage::PEOPLE_FILE)
    assert_equal expected_path, @people_storage.people_filepath
  end

  def test_load_people_creates_file_if_not_exists
    people_file = @people_storage.people_filepath
    File.delete(people_file) if File.exist?(people_file)

    people = @people_storage.load_people
    assert_instance_of Array, people
    assert_empty people
    assert File.exist?(people_file), 'People file should be created if it does not exist'
  end

  def test_load_people_returns_people_list
    create_example_people_file
    people = @people_storage.load_people
    assert_instance_of Array, people
    refute_empty people
    assert_equal 2, people.size
    assert_instance_of Person, people.first
    assert_equal 'alex', people.first.handle
    assert_equal 'laura', people.last.handle
  end

  def test_create_default_file
    people_file = @people_storage.people_filepath
    File.delete(people_file) if File.exist?(people_file)

    @people_storage.create_default_file
    assert File.exist?(people_file), 'People file should be created if it does not exist'

    # Calling again should not overwrite the existing file
    @people_storage.create_default_file
  end

  def test_write_people_file
    people_file = @people_storage.people_filepath
    File.delete(people_file) if File.exist?(people_file)

    people = [
      Person.new(handle: 'john', github_username: 'johntest', name: 'John Test',
                 team: 'Team C', email: 'john@example.com', role: 'Developer', inactive: false),
      Person.new(handle: 'jane', github_username: 'janetest', name: 'Jane Test',
                 team: 'Team D', email: 'jane@example.com', role: 'Manager', inactive: false)
    ]

    @people_storage.write_people!(people)
    loaded_people = @people_storage.load_people
    assert_equal people, loaded_people
  end

  def test_find_by_handle
    create_example_people_file
    test_cases = [
      ['alex', 'Alex Test'],
      ['laura', 'Laura Test'],
      ['nonexistent', nil]
    ]
    test_cases.each do |handle, expected_name|
      person = @people_storage.find_by_handle handle
      if expected_name
        assert_instance_of Person, person
        assert_equal expected_name, person.name
      else
        assert_nil person
      end
    end
  end

  def test_find_by_github_username
    create_example_people_file
    test_cases = [
      ['alextest', 'Alex Test'],
      ['lauratest', 'Laura Test'],
      ['nonexistent', nil]
    ]
    test_cases.each do |github_username, expected_name|
      person = @people_storage.find_by_github_username github_username
      if expected_name
        assert_instance_of Person, person
        assert_equal expected_name, person.name
      else
        assert_nil person
      end
    end
  end
end