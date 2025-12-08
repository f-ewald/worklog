# frozen_string_literal: true

module Worklog
  # Functions related to Github repositories
  module Github
    # Represents a GitHub repository with an owner and name.
    Repository = Struct.new(:owner, :name, keyword_init: true) do
      # Extracts the repository name and owner from a GitHub repository URL.
      # @param url [String] The GitHub repository URL or owner/repository string.
      # @return [Hash, nil] A hash with :owner and :repository keys, or nil if the URL is invalid.
      # @example
      #   repo = Worklog::Github::Repository.new
      #   repo.repository_from_url('https://github.com/owner/repository')
      #   # => <# owner: 'owner', repository: 'repository' }
      # @example
      #   repo.repository_from_url('owner/repository')
      #   # => #<struct Worklog::Github::Repository owner="owner", name="repository">
      def self.from_url(url)
        match = url.match(%r{github\.com[:/](?<owner>[^/]+)/(?<repo>[^/]+)(?:\.git)?$})
        match = url.match(%r{^(?<owner>[^/]+)/(?<repo>[^/]+)$}) if match.nil?
        return nil if match.nil?

        Repository.new(owner: match[:owner], name: match[:repo])
      end

      # Returns a string representation of the repository in the format "owner/name".
      # @return [String] The string representation of the repository.
      def to_s
        "#{owner}/#{name}"
      end
    end
  end
end
