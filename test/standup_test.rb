# frozen_string_literal: true

require_relative 'test_helper'
require 'minitest/autorun'
require 'standup'
require 'log_entry'

class StandupTest < Minitest::Test
  include Worklog

  def test_generate
    skip "Skipping test currently in development"
    entries = [
      LogEntry.new(
        message: 'Worked on feature X'
      ),
      LogEntry.new(
        message: 'Fixed bug Y'
      ),
      LogEntry.new(
        message: 'Planned for project Z'
      ),
    ]
    standup = Standup.new(entries)
    output = standup.generate
    assert output.is_a?(String)
  end
  def test_create_prompt
    entries = [
      LogEntry.new(
        message: 'Worked on feature X'
      ),
      LogEntry.new(
        message: 'Fixed bug Y'
      ),
      LogEntry.new(
        message: 'Planned for project Z'
      ),
    ]
    standup = Standup.new(entries)
    system_prompt, user_prompt = standup.create_prompt
    _ = system_prompt

    expected_output = [
      'Worked on feature X',
      'Fixed bug Y',
      'Planned for project Z'
    ]

    expected_output.each do |line|
      assert_includes(user_prompt, line)
    end
  end
end