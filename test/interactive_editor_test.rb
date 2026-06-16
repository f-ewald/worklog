# frozen_string_literal: true

require_relative 'test_helper'
require 'minitest/autorun'
require 'interactive_editor'
require 'log_entry'
require 'editor'

class InteractiveEditorTest < Minitest::Test
  def setup
    @entry = Worklog::LogEntry.new(
      time: Time.parse('2025-01-22 10:00:00 UTC'),
      message: 'Original message',
      tags: ['test'],
      ticket: 'TICK-123',
      url: 'https://example.com',
      epic: false,
      project: 'myproject',
      source: 'manual'
    )
    @original_editor_method = Editor.method(:open_editor)
  end

  def teardown
    # Restore the original editor method
    Editor.define_singleton_method(:open_editor, @original_editor_method)
  end

  # Helper method to mock the editor
  def mock_editor_with(return_value)
    Editor.define_singleton_method(:open_editor) { |_text| return_value }
  end

  def test_edit_entry_with_valid_changes # rubocop:disable Minitest/MultipleAssertions
    # Mock Editor.open_editor to return modified YAML
    updated_yaml = <<~YAML
      ---
      time: 2025-01-22 10:00:00.000000000 Z
      message: Updated message
      tags:
      - test
      - updated
      ticket: TICK-123
      url: https://example.com
      epic: false
      project: myproject
      source: manual
    YAML

    mock_editor_with(updated_yaml)

    result = Worklog::InteractiveEditor.edit_entry(@entry)

    refute_nil result
    assert_instance_of Worklog::LogEntry, result
    assert_equal 'Updated message', result.message
    assert_equal %w[test updated], result.tags
  end

  def test_edit_entry_with_invalid_yaml
    # Mock Editor.open_editor to return invalid YAML
    invalid_yaml = <<~YAML
      ---
      time: invalid_time_format
      message: [this is not a valid structure
    YAML

    mock_editor_with(invalid_yaml)

    result = Worklog::InteractiveEditor.edit_entry(@entry)

    assert_nil result
  end

  def test_edit_entry_with_no_changes
    # Mock Editor.open_editor to return unchanged YAML
    original_yaml = @entry.to_yaml

    mock_editor_with(original_yaml)

    result = Worklog::InteractiveEditor.edit_entry(@entry)

    # Should return nil when no changes are made
    assert_nil result
  end

  def test_edit_entry_preserves_all_fields # rubocop:disable Minitest/MultipleAssertions
    # Mock Editor.open_editor to return YAML with all fields
    updated_yaml = <<~YAML
      ---
      time: 2025-01-22 10:00:00.000000000 Z
      message: Updated message
      tags:
      - test
      - another
      ticket: TICK-456
      url: https://updated.example.com
      epic: true
      project: newproject
      source: github
    YAML

    mock_editor_with(updated_yaml)

    result = Worklog::InteractiveEditor.edit_entry(@entry)

    refute_nil result
    assert_equal 'Updated message', result.message
    assert_equal %w[test another], result.tags
    assert_equal 'TICK-456', result.ticket
    assert_equal 'https://updated.example.com', result.url
    assert(result.epic)
    assert_equal 'newproject', result.project
    assert_equal 'github', result.source
  end
end
