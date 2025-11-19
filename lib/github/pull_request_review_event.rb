# frozen_string_literal: true

require 'hasher'
require 'log_entry'
require 'worklogger'

module Worklog
  module Github
    # Event representing a pull request review
    # @!attribute [rw] repository
    #  @return [String] the repository name
    # @!attribute [rw] number
    #  @return [Integer] the pull request number
    # @!attribute [rw] url
    #  @return [String] the URL of the pull request review
    # @!attribute [rw] title
    #  @return [String] the title of the pull request
    # @!attribute [rw] description
    #  @return [String] the description of the pull request
    # @!attribute [rw] created_at
    #  @return [Time] the creation time of the pull request review, not the pull request itself
    # @!attribute [rw] state
    #  @return [String] the state of the review (e.g., 'approved', 'changes_requested', etc.)
    class PullRequestReviewEvent
      attr_accessor :repository, :number, :url, :title, :description, :created_at, :state

      def initialize(params = {})
        params.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
      end

      # Whether the pull request review was approved
      # @return [Boolean]
      def approved?
        state.downcase == 'approved'
      end

      # Convert the PullRequestReviewEvent to a LogEntry
      # @return [LogEntry]
      def to_log_entry
        message = 'Reviewed '
        message += 'and approved ' if approved?
        message += "PR ##{number}: #{title}"
        LogEntry.new(
          key: Hasher.sha256("#{repository}-#{number}-#{state}"),
          source: 'github',
          time: created_at,
          message: message,
          url: url
        )
      end

      # String representation of the PullRequestReviewEvent
      # @return [String]
      def to_s
        "#<PullRequestReviewEvent repository=#{repository} number=#{number} state=#{state} created_at=#{created_at}>"
      end
    end
  end
end
