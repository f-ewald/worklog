# frozen_string_literal: true

require 'hasher'
require 'log_entry'
require 'worklogger'

module Worklog
  module Github
    # An event representing a pull request
    # @!attribute [rw] repository
    #  @return [String] the repository name
    # @!attribute [rw] number
    #  @return [Integer] the pull request number
    # @!attribute [rw] url
    #  @return [String] the URL of the pull request
    # @!attribute [rw] title
    #  @return [String] the title of the pull request
    # @!attribute [rw] description
    #  @return [String] the description of the pull request
    # @!attribute [rw] created_at
    #  @return [Time] the creation time of the pull request
    # @!attribute [rw] merged_at
    #  @return [Time, nil] the time the pull request was merged, or nil if not merged
    # @!attribute [rw] closed_at
    #  @return [Time, nil] the time the pull request was closed, or nil if not closed
    class PullRequestEvent
      attr_accessor :repository, :number, :url, :title, :description, :created_at, :merged_at, :closed_at

      def initialize(params = {})
        params.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
      end

      # Returns true if the pull request was merged.
      # Usually, a merged pull request is also closed.
      # @return [Boolean] true if merged, false otherwise
      def merged?
        !merged_at.nil?
      end

      # Returns true if the pull request was closed.
      # A closed pull request may or may not be merged.
      # @return [Boolean] true if closed, false otherwise
      # @see #merged?
      def closed?
        # Treat merged pull requests as closed
        !closed_at.nil? || (merged? && closed_at.nil?)
      end

      # Convert the PullRequestEvent to a LogEntry
      # @return [LogEntry]
      def to_log_entry(*)
        message = if merged?
                    'Merged PR '
                  elsif closed?
                    'Closed PR '
                  else
                    'Opened PR '
                  end
        message += title

        # If merged, use merged_at time; if closed, use closed_at time; otherwise, use created_at time
        time = if merged?
                 merged_at
               elsif closed?
                 closed_at
               else
                 created_at
               end
        key = Hasher.sha256("#{repository}#{number}#{merged?}#{closed?}")
        LogEntry.new(
          key:,
          source: 'github',
          time:,
          message:,
          url: url,
          epic: false,
          ticket: nil
        )
      end

      # String representation of the PullRequestEvent
      # @return [String]
      def to_s
        short_url = url.length > 10 ? "...#{url[-10..]}" : url
        unless description.nil?
          short_description = description.gsub(/\n+/, ' ')
          short_description = "#{short_description[0..16]}..." if short_description.length > 20
        end
        "#<PullRequestEvent repository=#{repository} number=#{number} url=#{short_url} title=#{title} " \
          "description=#{short_description} " \
          "created_at=#{created_at} merged_at=#{merged_at} closed_at=#{closed_at}>"
      end
    end
  end
end
