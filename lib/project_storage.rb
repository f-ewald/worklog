# frozen_string_literal: true

require 'project'

module Worklog
  # Custom error for when a project is not found.
  # This error is raised when a project with a given key does not exist in the project storage.
  # It is used to signal that an operation requiring a project cannot proceed.
  class ProjectNotFoundError < StandardError; end

  # ProjectStorage is responsible for loading and managing project data.
  # It provides methods to load projects from a YAML file and check if a project exists.
  # @!attribute [w] projects
  #  @return [Hash<String, Project>] A hash of projects keyed by their project keys.
  #
  # @see Project
  # @see Configuration
  # Handles storage operations for projects.
  class ProjectStorage
    attr_writer :projects

    # The name of the YAML file where projects are stored.
    FILE_NAME = 'projects.yaml'

    # The template for the projects YAML file.
    # This template is used to create a new projects file if it does not exist.
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

    # Constructs a new ProjectStorage instance.
    # @param configuration [Configuration] The configuration object.
    def initialize(configuration)
      @configuration = configuration
    end

    # Returns all loaded projects.
    # If the projects are not already loaded, it loads them from disk.
    # @return [Hash<String, Project>] A hash of project objects keyed by their unique project keys.
    def projects
      @projects ||= load_projects
    end

    # Loads all projects from disk.
    # If the file does not exist, it creates a template.
    # @return [Hash<String, Project>] A hash of project objects keyed by their project keys.
    def load_projects
      create_template unless file_exist?

      file_path = File.join(@configuration.storage_path, FILE_NAME)
      projects = {}
      YAML.load_file(file_path, permitted_classes: [Date])&.each do |project_hash|
        project = Project.from_hash(project_hash)
        projects[project.key] = project if project
      end

      projects
    end

    # Check if a project with a given key exists.
    # @param key [String] The key of the project to check.
    # @return [Boolean] Returns true if the project exists, false otherwise.
    # @note This method loads the projects from disk if they are not already loaded.
    # @see load_projects
    def exist?(key)
      projects = load_projects
      projects.key?(key)
    end

    # Alias for exist? method.
    # @param key [String] The key of the project to check.
    # @return [Boolean] Returns true if the project exists, false otherwise.
    def key?(key) = exist?(key)

    private

    # Check whether projects.yaml exists in the project_dir
    # @return [Boolean] Returns true if the project YAML file exists, false otherwise
    def file_exist?
      file_path = File.join(@configuration.storage_path, FILE_NAME)
      File.exist?(file_path)
    end

    # Creates a template for the projects YAML file if it does not exist.
    # This method writes a predefined template to the projects.yml file.
    # @return [void]
    # @note This method will overwrite any existing projects.yml file.
    # @see PROJECT_TEMPLATE for the structure of the template.
    def create_template
      return unless @configuration.storage_path_exist?

      File.write(File.join(@configuration.storage_path, FILE_NAME), PROJECT_TEMPLATE)
      nil
    end
  end
end
