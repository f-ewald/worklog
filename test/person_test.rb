# frozen_string_literal: true

require_relative 'test_helper'
require 'minitest/autorun'
require 'person'

class PersonTest < Minitest::Test
  include Worklog

  def setup
    @john_doe = Person.new(handle: 'jdoe', name: 'John Doe', email: 'john_doe@example.org', team: 'Engineering', notes: %w[Note1 Note2])
    @alice = Person.new(handle: 'asmith', name: 'Alice Smith', email: nil, team: 'Marketing', notes: [])
  end

  def test_initialize
    refute_nil @john_doe
    refute_nil @alice
  end

  def test_to_s
    assert_equal 'John Doe (~jdoe) <john_doe@example.org>', @john_doe.to_s

    person = Person.new(handle: 'jdoe', name: 'John Doe', email: nil, team: 'Engineering', notes: [])
    assert_equal 'John Doe (~jdoe)', person.to_s
  end

  def test_from_hash
    hash = {
      'handle' => 'jdoe',
      'name' => 'John Doe',
      'email' => 'john_doe@example.org',
      'team' => 'Engineering',
      'notes' => ['Note1', 'Note2']
    }
    person = Person.from_hash(hash)
    assert_equal 'jdoe', person.handle
    assert_equal 'John Doe', person.name
    assert_equal 'john_doe@example.org', person.email
    assert_equal 'Engineering', person.team
    assert_equal ['Note1', 'Note2'], person.notes
  end

  def test_from_sym_hash
    hash = {
      handle: 'asmith',
      name: 'Alice Smith',
      email: nil,
      team: 'Marketing',
      notes: []
    }
    person = Person.from_hash(hash)
    assert_equal 'asmith', person.handle
    assert_equal 'Alice Smith', person.name
    assert_nil person.email
    assert_equal 'Marketing', person.team
    assert_equal [], person.notes
  end

  def test_from_hash_missing_handle
    hash = {
      'name' => 'John Doe'
    }
    assert_raises(ArgumentError) { Person.from_hash(hash) }
  end

  def test_from_hash_missing_name
    hash = {
      'handle' => 'jdoe'
    }
    assert_raises(ArgumentError) { Person.from_hash(hash) }
  end
end
