# frozen_string_literal: true

require 'github/repository'

module Worklog
  # Represents a project. A project is a longer running task or initiative.
  # Single log entries can be associated with a project.
  # @!attribute [rw] key
  #   @return [String] Unique identifier for the project, used in log entries.
  # @!attribute [rw] name
  #   @return [String] The human-readable name of the project.
  # @!attribute [rw] description
  #   @return [String, nil] A description of the project, can be nil
  # @!attribute [rw] start_date
  #   @return [Date, nil] The start date of the project, can be nil
  # @!attribute [rw] end_date
  #   @return [Date, nil] The end date of the project, can be nil
  # @!attribute [rw] status
  #   @return [String, nil] The status of the project, can be nil
  #   Possible values: 'active', 'completed', 'archived', etc.
  #   Indicates the current state of the project.
  # @!attribute [rw] repositories
  #   @return [Array<String>] An array of repository URLs associated with the project.
  #   These repositories are used for linking the Github commits to the project.
  #   At the moment, only Github repositories are supported.
  # @!attribute [rw] entries
  #   These entries are related to the work done on this project.
  #   Entries are populated dynamically when processing daily logs.
  #   They are not stored in the project itself.
  #   @return [Array<LogEntry>] An array of log entries associated with the project.
  # @!attribute [rw] last_activity
  #   The last activity is not stored in the project itself.
  #   Instead, it is updated dynamically when processing daily logs.
  #   It represents the most recent log entry time for this project.
  #   @return [Date, nil] The last activity date or nil if not set.
  class Project
    attr_accessor :key, :name, :description, :start_date, :end_date, :status, :repositories, :entries, :last_activity

    # Creates a new Project instance from a hash of attributes.
    # @param hash [Hash] A hash containing project attributes
    # @option hash [String] :key The project key
    # @option hash [String] :name The project name
    # @option hash [String] :description The project description
    # @option hash [Date] :start_date The project start date
    # @option hash [Date] :end_date The project end date
    # @option hash [String] :status The project status
    # @return [Project] A new Project instance
    def self.from_hash(hash)
      project = new

      # Protect against nil hash
      raise ArgumentError, 'Project hash cannot be nil' if hash.nil?

      # Ensure that at least the key is present
      raise ArgumentError, 'Project key is required' unless hash[:key] || hash['key']

      hash.each do |key, value|
        instance_var = "@#{key}"
        project.instance_variable_set(instance_var, value) if project.respond_to?("#{key}=")
      end
      # Set default values for repositories if not provided
      project.repositories ||= []
      project.repositories.map! do |repo|
        Github::Repository.from_url(repo)
      end

      project
    end

    # Returns true if the project has started, false otherwise.
    # A project is considered started if either
    #  - its start date is nil or
    #  - its start date is less than or equal to today's date.
    # @return [Boolean] true if the project has started, false otherwise
    def started?
      start_date.nil? || (!start_date.nil? && start_date <= Date.today)
    end

    # Returns true if the project has ended, false otherwise.
    # @return [Boolean] true if the project has ended, false otherwise
    def ended?
      !end_date.nil? && end_date < Date.today
    end

    # Returns true if the project contains the given repository URL.
    # @param repository [Worklog::Github::Repository] The repository to check
    # @return [Boolean] true if the project contains the repository URL, false otherwise
    def contains_repository?(repository)
      repositories.include? repository
    end

    # Generate an ASCII activity graph for the project.
    # The graph shows activity over time, with each character representing a day.
    # More active days are represented with a different character.
    # @return [String] An ASCII representation of the activity graph.
    def activity_graph
      graph = String.new
      # Generate the graph for the last 30 days
      (0..29).each do |i|
        date = Date.today - i
        graph << if entries.any? { |entry| entry.time.to_date == date }
                   '#'
                 else
                   '.'
                 end
      end

      graph.reverse!

      graph << "\n"
      graph << "#{' ' * 31}^\n"
      graph << "#{' ' * 31}Today"
    end
  end
end
