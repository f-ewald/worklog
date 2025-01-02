# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../worklog/log_entry'

class TestLogEntry < Minitest::Test
  def setup
    @log_entry = LogEntry.new('10:00', ['tag1', 'tag2'], 'ticket-123', true, 'This is a message')
  end

  def test_time
    assert_equal '10:00', @log_entry.time
  end

  def test_tags
    assert_equal ['tag1', 'tag2'], @log_entry.tags
  end

  def test_ticket
    assert_equal 'ticket-123', @log_entry.ticket
  end

  def test_epic
    assert @log_entry.epic
    assert @log_entry.epic?
  end

  def test_message
    assert_equal 'This is a message', @log_entry.message
  end
end