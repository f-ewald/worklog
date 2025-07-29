# frozen_string_literal: true

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
  # @!attribute [rw] last_activity
  #  @return [Date, nil] The last activity date or nil if not set.
  class Project
    attr_accessor :key, :name, :description, :start_date, :end_date, :status, :last_activity

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
      # Ensure that at least the key is present
      raise ArgumentError, 'Project key is required' unless hash[:key] || hash['key']

      project.key = hash[:key] || hash['key']
      project.name = hash[:name] || hash['name']
      project.description = hash[:description] || hash['description']
      project.start_date = hash[:start_date] || hash['start_date']
      project.end_date = hash[:end_date] || hash['end_date']
      project.status = hash[:status] || hash['status']
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
  end
end
