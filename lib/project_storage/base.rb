# frozen_string_literal: true

require 'project'

module Worklog
  # Raised when a project with a given key cannot be found.
  class ProjectNotFoundError < StandardError; end

  module ProjectStorage
    # Abstract base class for project storage backends.
    class Base
      attr_writer :projects

      # @param config [Worklog::Configuration]
      def initialize(config)
        @configuration = config
      end

      # All projects keyed by their unique project key.
      # @return [Hash{String=>Project}]
      def projects
        @projects ||= load_projects
      end

      # Force-load all projects from the backend.
      # @return [Hash{String=>Project}]
      def load_projects
        raise NotImplementedError
      end

      # @param key [String]
      # @return [Boolean]
      def exist?(key)
        load_projects.key?(key)
      end

      # @param key [String]
      # @return [Boolean]
      def key?(key) = exist?(key)

      # Filter projects whose attributes match the provided hash.
      # @param filters [Hash{Symbol=>Object}]
      # @return [Array<Project>]
      def find_by(filters = {})
        projects.values.select do |project|
          filters.all? { |k, v| project.respond_to?(k) && project.public_send(k) == v }
        end
      end

      # Optional: create a default file/template on first run.
      # @return [void]
      def create_default_file; end

      # Replace all projects in the backend with the provided list.
      # Used by `wl storage import` and the contract tests.
      # @param projects [Array<Project>]
      # @return [void]
      def write_projects!(_projects)
        raise NotImplementedError
      end
    end
  end
end
