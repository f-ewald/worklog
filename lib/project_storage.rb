# frozen_string_literal: true

require 'project'

module Worklog
  # Custom error for when a project is not found.
  # This error is raised when a project with a given key does not exist in the project storage.
  # It is used to signal that an operation requiring a project cannot proceed.
  class ProjectNotFoundError < StandardError; end

  # ProjectStorage is responsible for loading and managing project data.
  # It provides methods to load projects from a YAML file and check if a project exists.
  #
  # @see Project
  # @see Configuration
  # Handles storage operations for projects.
  class ProjectStorage
    attr_writer :projects

    PROJECT_TEMPLATE = <<~YAML
      # Each project is defined by the following attributes:
      # - key: <project_key>
      #   name: <project_name>
      #   description: <project_description>
      #   start_date: <start_date>
      #   end_date: <end_date>
      #   status: <status>
      #   --- Define your projects below this line ---
    YAML

    # Constructs a new ProjectStorage instance.
    # @param configuration [Configuration] The configuration object.
    def initialize(configuration)
      @configuration = configuration
    end

    def projects
      @projects ||= load_projects
    end

    # Loads all projects from disk.
    # If the file does not exist, it creates a template.
    # @return [Hash<String, Project>] A hash of project objects keyed by their project keys.
    def load_projects
      create_template unless file_exist?

      file_path = File.join(@configuration.storage_path, 'projects.yml')
      projects = {}
      YAML.load_file(file_path, permitted_classes: [Date])&.each do |project_hash|
        project = Project.from_hash(project_hash)
        projects[project.key] = project if project
      end

      projects
    end

    # Check if a project with a given handle exists.
    # @param handle [String] The handle of the project to check.
    # @return [Boolean] Returns true if the project exists, false otherwise.
    def exist?(handle)
      projects = load_projects
      projects.key?(handle)
    end

    private

    # Check whether projects.yaml exists in the project_dir
    # @return [Boolean] Returns true if the project YAML file exists, false otherwise
    def file_exist?
      file_path = File.join(@configuration.storage_path, 'projects.yml')
      File.exist?(file_path)
    end

    def create_template
      File.write(File.join(@configuration.storage_path, 'projects.yml'), PROJECT_TEMPLATE)
    end
  end
end
