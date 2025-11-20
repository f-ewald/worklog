# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'github/pull_request_review_event'

class PullRequestReviewEventTest < Minitest::Test
  include Worklog
  include Github

  def setup
    @event = PullRequestReviewEvent.new(
      repository: 'sample-org/sample-repo',
      number: 42,
      state: 'approved',
      title: 'PR Title',
      description: 'PR description',
      creator: 'creator-username',
      url: 'https://github.com/sample-org/sample-repo/pull/42#pullrequestreview-1234'
    )
    @log_entry = @event.to_log_entry
  end

  def test_initialize_repository
    assert_equal 'sample-org/sample-repo', @event.repository
  end

  def test_initialize_number
    assert_equal 42, @event.number
  end

  def test_initialize_state
    assert_equal 'approved', @event.state
  end

  def test_initialize_title
    assert_equal 'PR Title', @event.title
  end

  def test_initialize_url
    assert_equal 'https://github.com/sample-org/sample-repo/pull/42#pullrequestreview-1234', @event.url
  end

  def test_initialize_description
    assert_equal 'PR description', @event.description
  end

  def test_to_log_entry_key
    expected_key = Hasher.sha256('sample-org/sample-repo-42-approved')

    assert_equal expected_key, @log_entry.key
    assert_equal 'github', @log_entry.source
    assert_equal 7, @log_entry.key.length
  end

  def test_to_log_entry_source
    assert_equal 'github', @log_entry.source
  end

  def test_to_log_entry
    assert_instance_of LogEntry, @log_entry
    refute_nil @log_entry.key
    assert_includes @log_entry.message, 'PR Title'
  end

  def test_to_log_entry_approved
    assert_includes @log_entry.message, 'and approved'
  end

  def test_approved?
    assert_predicate @event, :approved?
  end

  def test_to_s
    expected_str = '#<PullRequestReviewEvent repository=sample-org/sample-repo number=42 state=approved creator=creator-username created_at=>' # rubocop:disable Layout/LineLength

    assert_equal expected_str, @event.to_s
  end
end
