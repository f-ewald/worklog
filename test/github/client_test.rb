# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'github/client'

class GithubTest < Minitest::Test
  include Worklog::Github

  def setup
    @configuration = configuration_helper
    @github = Client.new(@configuration)
    @repo = 'sample-org/sample-repo'
    @pr_number = 109
  end

  def load_fixture(filename)
    file_path = File.join(__dir__, 'data', filename)
    events = JSON.parse(File.read(file_path))
    events.filter { |event| Client::EVENT_FILTER.include?(event['type']) }
  end

  # General test for get_events with pagination
  def test_get_events
    fixture = load_fixture('github_events.json')
    @github.stub(:github_api_get, ->(_url) { fixture }) do
      @github.stub(:pull_request_details, PullRequestDetails.new) do
        events = @github.get_events

        assert_kind_of Array, events
        assert_equal fixture.size * 3, events.size

        # Assert type for each event
        events.each do |event|
          assert_includes [PullRequestEvent, PushEvent, PullRequestReviewEvent],
                          event.class
        end
      end
    end
  end

  # Test parsing of a PullRequestReviewEvent
  def test_pull_request_review_event
    fixture = load_fixture('pull_request_review_event.json')
    pr_details = PullRequestDetails.new(
      title: 'Pull Request Review Title',
      description: 'Description of the pull request.'
    )
    @github.stub(:github_api_get, ->(_url) { fixture }) do
      @github.stub(:pull_request_details, pr_details) do
        events = @github.get_events

        assert_kind_of Array, events

        # Pagination returns 3 pages of the same fixture
        assert_equal fixture.size * 3, events.size

        assert_kind_of PullRequestReviewEvent, events.first
        first = events.first

        assert_equal 'sample-org/sample-repo', first.repository
        assert_equal 511, first.number
        assert_equal 'https://github.com/sample-org/sample-repo/pull/511#pullrequestreview-1234', first.url
        assert_equal 'Pull Request Review Title', first.title
        assert_equal 'Description of the pull request.', first.description
        assert_equal 'approved', first.state
      end
    end
  end

  # Test parsing of a PullRequestEvent
  def test_pull_request_event
    fixture = load_fixture('pull_request_event.json')
    pr_details = PullRequestDetails.new(
      title: 'Add new feature',
      description: 'This PR adds a new feature.',
      url: 'https://github.com/sample-org/sample-repo/pull/446',
      created_at: '2021-09-01T12:34:56Z',
      merged_at: '2021-09-02T12:34:56Z',
      closed_at: '2021-09-02T12:34:56Z'
    )
    @github.stub(:github_api_get, ->(_url) { fixture }) do
      @github.stub(:pull_request_details, pr_details) do
        events = @github.get_events

        assert_kind_of Array, events

        # Pagination returns 3 pages of the same fixture
        assert_equal fixture.size * 3, events.size

        assert_kind_of PullRequestEvent, events.first
        event = events.first

        assert_equal 'sample-org/sample-repo', event.repository
        assert_equal 446, event.number
        assert_equal pr_details.url, event.url
        assert_equal pr_details.title, event.title
        assert_equal pr_details.description, event.description
        assert_equal '2021-09-01T12:34:56Z', event.created_at
        assert_equal '2021-09-02T12:34:56Z', event.merged_at
        assert_equal '2021-09-02T12:34:56Z', event.closed_at
      end
    end
  end

  # Test parsing of a PushEvent
  def test_push_event
    fixture = load_fixture('push_event.json')
    @github.stub(:github_api_get, ->(_url) { fixture }) do
      events = @github.get_events

      assert_kind_of Array, events
      puts events.first.class

      assert_kind_of NilClass, events.first
      assert_equal fixture.size * 3, events.size
    end
  end

  def test_pull_request_data
    skip 'WIP: Implement persistent stubs for pull_request_data'
    pr_data = @github.pull_request_data(@repo, @pr_number)

    assert_equal @pr_number, pr_data['number']
    assert pr_data.key?('title')
    assert pr_data.key?('body')
  end

  def test_pull_request_comments
    skip 'Fix this test later'
    comments = @github.pull_request_comments(@repo, @pr_number)

    assert_kind_of Array, comments
    comments.each do |comment|
      assert comment.key?('id')
      assert comment.key?('body')
    end
  end

  def test_missing_token
    @configuration.github.api_key = nil
    github_client = Client.new(@configuration)

    error = assert_raises(Client::GithubAPIError) do
      github_client.get_events
    end

    assert_equal 'GitHub API key is not configured. Please set it in the configuration.', error.message
  end
end
