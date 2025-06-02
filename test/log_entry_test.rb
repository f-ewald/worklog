# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'
require 'log_entry'
require 'person'

class LogEntryTest < Minitest::Test
  def setup
    @log_entry = LogEntry.new(time: '10:00', tags: ['tag1', 'tag2'], ticket: 'ticket-123', url: 'https://example.com/', epic: true, message: 'This is a message')
  end

  def test_time
    assert_equal '10:00', @log_entry.time
  end

  def test_tags
    assert_equal ['tag1', 'tag2'], @log_entry.tags
  end

  def test_empty_tags
    # Empty tags should be converted to an empty array.
    assert_empty LogEntry.new(time: '10:00', ticket: 'ticket-123', url: 'https://example.com/', epic: true, message: 'This is a message').tags
  end

  def test_ticket
    assert_equal 'ticket-123', @log_entry.ticket
  end

  def test_url
    assert_equal 'https://example.com/', @log_entry.url
  end

  def test_epic
    assert @log_entry.epic
    assert_predicate @log_entry, :epic?
  end

  def test_message
    assert_equal 'This is a message', @log_entry.message
  end

  def test_equality
    assert_equal LogEntry.new(time: '10:00', tags: ['tag1', 'tag2'], ticket: 'ticket-123', url: 'https://example.com/', epic: true, message: 'This is a message'), @log_entry
  end

  def test_message_string
    msg_string = @log_entry.message_string

    assert_includes msg_string, 'This is a message'
    assert_includes msg_string, '[EPIC]'
    assert_includes msg_string, 'tag1'
    assert_includes msg_string, 'tag2'
    assert_includes msg_string, 'ticket-123'

    @log_entry.epic = false
    msg_string = @log_entry.message_string
    assert_includes msg_string, 'This is a message'
  end

  def test_message_string_replace_people
    known_people = {
      'person1' => Person.new('person1', 'Person One', '', 'Team A'),
      'person2' => Person.new('person2', 'Person Two', '', 'Team A')
    }
    msg_string = LogEntry.new(message: 'This is a message with a mention of ~person1 and ~person2').message_string(known_people)
    refute_nil msg_string
    assert_includes msg_string, 'Person One'
    assert_includes msg_string, 'Person Two'
  end

  def test_people?
    # Default case has no people.
    refute @log_entry.people?

    @log_entry.message = 'This is a message with a mention of ~person1'
    assert @log_entry.people?
  end

  def test_people
    # Default case has no people.
    assert_empty @log_entry.people

    @log_entry.message = 'This is a message with a mention of ~person1 and ~person2'
    assert_equal %w[person1 person2], @log_entry.people

    # This is not a person because the tilde is not at the start.
    @log_entry.message = 'This is a message with a mention of~person1'
    assert_empty @log_entry.people

    # Test uniqueness.
    @log_entry.message = 'This is a message with a mention of ~person1 and ~person1'
    assert_equal %w[person1], @log_entry.people

    # Test tilde only
    @log_entry.message = 'This is a message with a mention of ~ and ~'
    assert_empty @log_entry.people

    # Test numbers only
    @log_entry.message = 'This is a message with a mention of ~123 and ~456'
    assert_equal %w[123 456], @log_entry.people

    # Test punctuation
    @log_entry.message = 'This is a message with a mention of ~person1, ~person2, and ~person3'
    assert_equal %w[person1 person2 person3], @log_entry.people

    # Test sorting
    @log_entry.message = 'This is a message with a mention of ~person2, ~person1, and ~person3'
    assert_equal %w[person1 person2 person3], @log_entry.people

    # Test @ sign
    @log_entry.message = 'This is a message with a mention of @person1 and @person2'
    assert_equal %w[person1 person2], @log_entry.people
  end

  def test_to_yaml
    yaml = @log_entry.to_yaml

    refute_nil yaml
  end
end
