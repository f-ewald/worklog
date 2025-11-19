# frozen_string_literal: true

require 'httparty'
require 'github/pull_request_details'
require 'github/pull_request_event'
require 'github/pull_request_review_event'
require 'github/push_event'
require 'tzinfo'
require 'worklogger'

module Worklog
  module Github
    # Client to interact with GitHub API
    class Client
      class GithubAPIError < StandardError; end

      EVENT_FILTER = Set.new(%w[
                               PullRequestEvent
                               PullRequestReviewEvent

                             ]).freeze

      def initialize(configuration)
        @configuration = configuration
      end

      # Fetch events for a given user from Github API
      def get_events
        verify_token!

        WorkLogger.debug 'Fetching most recent GitHub events...'
        responses = fetch_events
        events = []

        responses.each do |event|
          # Payload is available for each event
          payload = event['payload']

          case event['type']
          when 'PullRequestEvent'
            repo = event['repo']

            # Retrieve details for the specific pull request
            pr_details = pull_request_details(repo['name'], payload['number'])

            events << PullRequestEvent.new(
              repository: repo['name'],
              number: payload['number'],
              url: pr_details.url,
              title: pr_details.title,
              description: pr_details.description,
              created_at: pr_details.created_at,
              merged_at: pr_details.merged_at,
              closed_at: pr_details.closed_at
            )
          when 'PushEvent'
            # Handle PushEvent if needed
            # TODO: Check if really needed
            # events << PushEvent.new
          when 'PullRequestReviewEvent'
            repo_name = event['repo']['name']
            pr_number = payload['pull_request']['number']

            review = payload['review']
            review_state = review['state']
            url = review['html_url']
            created_at = to_local_time(review['submitted_at'])

            pr_details = pull_request_details(repo_name, pr_number)

            events << PullRequestReviewEvent.new(
              repository: repo_name,
              number: pr_number,
              url:,
              title: pr_details.title,
              description: pr_details.description,
              state: review_state,
              created_at: created_at
            )
          else
            # Ignore other event types
            # TODO: Ignore the events silently
            WorkLogger.debug "Unhandled event type: #{event['type']}, skipping."

          end
        end

        events
      end

      def pull_request_data(repo, pr_number)
        response = HTTParty.get("https://api.github.com/repos/#{repo}/pulls/#{pr_number}",
                                headers: { 'Authorization' => "token #{TOKEN}" })
        response.parsed_response
      end

      def pull_request_comments(repo, pr_number)
        response = HTTParty.get("https://api.github.com/repos/#{repo}/pulls/#{pr_number}/comments",
                                headers: { 'Authorization' => "token #{TOKEN}" })
        response.parsed_response
      end

      private

      # Get detailed information about a specific pull request
      # @param repo [String] Repository name in the format 'owner/repo'
      # @param pr_number [Integer] Pull request number
      # @return [PullRequestDetails] Struct containing pull request details
      def pull_request_details(repo, pr_number)
        WorkLogger.debug "Fetching details for PR ##{pr_number} in #{repo}..."
        response = HTTParty.get("https://api.github.com/repos/#{repo}/pulls/#{pr_number}",
                                headers: { 'Authorization' => "token #{@configuration.github.api_key}" })
        WorkLogger.debug "Received response with HTTP code #{response.code} for PR ##{pr_number} in #{repo}."
        if response.code == 403
          raise GithubAPIError,
                'Failed to fetch PR details: Are you connected to the corporate VPN? (HTTP 403 Forbidden)'
        elsif response.code != 200
          raise GithubAPIError, "Failed to fetch PR details: HTTPCode #{response.code}"
        end

        pr = response.parsed_response
        PullRequestDetails.new(
          title: pr['title'],
          description: pr['body'],
          url: pr['html_url'],
          state: pr['state'],
          merged: pr['merged'],
          created_at: to_local_time(pr['created_at']),
          merged_at: to_local_time(pr['merged_at']),
          closed_at: to_local_time(pr['closed_at'])
        )
      end

      # Generic method to perform GET requests to GitHub API
      def github_api_get(url)
        response = HTTParty.get(url, headers: { 'Authorization' => "token #{@configuration.github.api_key}" })
        raise GithubAPIError, "GitHub API request failed with code #{response.code}" unless response.code == 200

        # TODO: Respect rate limit headers
        # headers = response.headers
        # puts "Remaining: #{headers['X-RateLimit-Remaining']}"
        # puts "Reset: #{headers['X-RateLimit-Reset']}"
        # puts "Limit: #{headers['X-RateLimit-Limit']}"
        # puts "Used: #{headers['X-RateLimit-Used']}"
        response.parsed_response
      end

      # Fetch the maximum number of events with pagination for the configured user
      # @return [Array<Hash>] Array of event hashes
      def fetch_events
        responses = []
        (1..3).each do |page|
          responses += github_api_get("https://api.github.com/users/#{@configuration.github.username}/events?per_page=100&page=#{page}")
        end
        responses
      end

      # Convert a DateTime to local time based on configuration timezone
      # @param time [Time, String] The Time to convert
      # @return [Time, nil] The converted Time in local time, or nil if input is nil
      def to_local_time(time)
        return nil if time.nil?

        time = Time.parse(time) if time.is_a?(String)

        @configuration.timezone.utc_to_local(time)
      end

      def verify_token!
        @configuration.github.api_key || raise(GithubAPIError,
                                               'GitHub API key is not configured. Please set it in the configuration.')
      end
    end
  end
end
