# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'log_entry'
require 'github/pull_request_event'

class PullRequestEventTest < Minitest::Test
  include Worklog
  include Worklog::Github

  def setup
    @event = PullRequestEvent.new(
      repository: 'sample-org/sample-repo',
      number: 42,
      url: 'https://github.com/sample-org/sample-repo/pull/42',
      title: 'Sample Pull Request',
      description: 'This is a sample pull request for testing.',
      created_at: Time.parse('2024-01-01T12:00:00Z'),
      merged_at: Time.parse('2024-01-02T12:00:00Z'),
      closed_at: Time.parse('2024-01-03T12:00:00Z')
    )

    @log_entry = @event.to_log_entry
  end

  def test_initialize_empty
    assert_instance_of PullRequestEvent, @event
  end

  def test_initialize_repository
    assert_equal 'sample-org/sample-repo', @event.repository
  end

  def test_initialize_number
    assert_equal 42, @event.number
  end

  def test_initialize_url
    assert_equal 'https://github.com/sample-org/sample-repo/pull/42', @event.url
  end

  def test_initialize_title
    assert_equal 'Sample Pull Request', @event.title
  end

  def test_initialize_description
    assert_equal 'This is a sample pull request for testing.', @event.description
  end

  def test_initialize_created_at
    assert_equal Time.parse('2024-01-01T12:00:00Z'), @event.created_at
  end

  def test_initialize_merged_at
    assert_equal Time.parse('2024-01-02T12:00:00Z'), @event.merged_at
  end

  def test_initialize_closed_at
    assert_equal Time.parse('2024-01-03T12:00:00Z'), @event.closed_at
  end

  def test_merged?
    assert_predicate @event, :merged?
  end

  def test_closed?
    assert_predicate @event, :closed?
  end

  def test_to_log_entry
    assert_instance_of LogEntry, @log_entry
    assert_equal Hasher.sha256('sample-org/sample-repo42'), @log_entry.key
    assert_equal 'github', @log_entry.source
  end

  def test_log_entry_time
    assert_equal Time.parse('2024-01-01T12:00:00Z'), @log_entry.time
  end

  def test_log_entry_message
    assert_includes @log_entry.message, 'Sample Pull Request'
  end

  def test_log_entry_url
    assert_equal 'https://github.com/sample-org/sample-repo/pull/42', @log_entry.url
  end

  def test_to_s
    expected_string = '#<PullRequestEvent repository=sample-org/sample-repo number=42 url=https://github.com/sample-org/sample-repo/pull/42 title=Sample Pull Request description=This is a sample pull request for testing. created_at=2024-01-01T12:00:00+00:00 merged_at=2024-01-02T12:00:00+00:00 closed_at=2024-01-03T12:00:00+00:00>'

    assert_equal expected_string, @event.to_s
  end
end
