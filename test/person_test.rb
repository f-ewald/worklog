# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'
require 'person'

class PersonTest < Minitest::Test
  def setup
    @john_doe = Person.new('jdoe', 'John Doe', 'john_doe@example.org', 'Engineering', %w[Note1 Note2])
  end

  def test_initialize
    refute_nil @john_doe
  end

  def test_to_s
    person = Person.new('jdoe', 'John Doe', 'john_doe@example.org', 'Engineering', [])
    assert_equal 'John Doe (~jdoe) <john_doe@example.org>', person.to_s

    person = Person.new('jdoe', 'John Doe', nil, 'Engineering', [])
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
end
