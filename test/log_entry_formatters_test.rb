# frozen_string_literal: true

require_relative 'test_helper'
require 'log_entry_formatters'
require 'person'

class LogEntryFormattersTest < Minitest::Test
  include Worklog

  def setup
    @known_people = {
      'alice' => Person.new(handle: 'alice', name: 'Alice Smith'),
      'bob' => Person.new(handle: 'bob', name: 'Bob Johnson')
    }
    @log_entry = LogEntry.new(
      message: "Worked on the project with @alice and ~bob.",
      ticket: 'PROJ-123',
      tags: ['development', 'backend'],
      url: 'http://example.com/ticket/PROJ-123',
      project: 'Project X'
    )
  end

  def test_console_formatter
    formatter = LogEntryFormatters::ConsoleFormatter.new(@known_people)
    formatted_message = formatter.format(@log_entry)

    assert_includes formatted_message, 'Alice Smith'
    assert_includes formatted_message, 'Bob Johnson'
    assert_includes formatted_message, 'PROJ-123'
  end

  def test_simple_formatter
    formatter = LogEntryFormatters::SimpleFormatter.new(@known_people)
    formatted_message = formatter.format(@log_entry)

    assert_includes formatted_message, 'Alice Smith'
    assert_includes formatted_message, 'Bob Johnson'
    refute_includes formatted_message, 'PROJ-123'
  end
end