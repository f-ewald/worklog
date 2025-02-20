# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'
require_relative '../worklog/log_entry'

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
end
