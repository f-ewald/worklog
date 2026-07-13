# frozen_string_literal: true

require 'yaml'
require 'project'
require 'project_storage/base'

module Worklog
  module ProjectStorage
    # YAML-backed project storage. Projects live in a single
    # `projects.yaml` file under `config.storage_path`.
    class Yaml < Base
      FILE_NAME = 'projects.yaml'

      # Template seeded when the projects file does not yet exist.
      PROJECT_TEMPLATE = <<~YAML
        # Each project is defined by the following attributes:
        # - key: <project_key>
        #   name: <project_name>
        #   description: <project_description>
        #   start_date: <start_date>
        #   end_date: <end_date>
        #   status: <status>
        #   repositories:
        #     - <repository_url_1>
        #     - <repository_url_2>
        #   --- Define your projects below this line ---
      YAML

      # @return [Hash{String=>Project}]
      def load_projects
        create_template unless file_exist?

        projects = {}
        YAML.load_file(file_path, permitted_classes: [Date])&.each do |project_hash|
          project = Project.from_hash(project_hash)
          projects[project.key] = project if project
        end
        projects
      end

      # Replace the contents of projects.yaml with the given list.
      # @param projects [Array<Project>]
      # @return [void]
      def write_projects!(projects)
        raise ArgumentError, 'projects must be an array of Project objects' if projects.nil? || !projects.is_a?(Array)

        File.write(file_path, projects.map { |p| project_to_hash(p) }.to_yaml)
        @projects = projects.to_h { |project| [project.key, project] }
      end

      private

      # @return [String]
      def file_path
        File.join(@configuration.storage_path, FILE_NAME)
      end

      # @return [Boolean]
      def file_exist?
        File.exist?(file_path)
      end

      # Write the project template if missing. No-op when the storage
      # folder does not exist (keeps `Errno::ENOENT` behavior for the
      # error path in `load_projects`).
      # @return [void]
      def create_template
        return unless @configuration.storage_path_exist?

        File.write(file_path, PROJECT_TEMPLATE)
        nil
      end

      # Map a Project back to a plain hash for YAML serialization.
      # Used by {#write_projects!}.
      # @param project [Project]
      # @return [Hash]
      def project_to_hash(project)
        {
          'key' => project.key,
          'name' => project.name,
          'description' => project.description,
          'start_date' => project.start_date,
          'end_date' => project.end_date,
          'status' => project.status,
          'repositories' => Array(project.repositories).map(&:to_s)
        }.compact
      end
    end
  end
end
