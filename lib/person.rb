# frozen_string_literal: true

module Worklog
  # Represents a person at work.
  #
  # !attribute [r] handle
  #  @return [String] The person's handle (username)
  # !attribute [r] name
  #  @return [String] The person's full name
  # !attribute [r] email
  #  @return [String, nil] The person's email address, can be nil
  # !attribute [r] team
  #  @return [String, nil] The team the person belongs to, can be nil
  # !attribute [r] notes
  #  @return [Array<String>] An array of notes about the person
  #  !attribute [r] inactive
  #  @return [Boolean] Whether the person is inactive (for example left the company)
  class Person
    attr_reader :handle, :github_username, :name, :email, :team, :notes, :inactive

    def initialize(handle:, name:, **params)
      # params to symbol keys
      params = params.transform_keys(&:to_sym)

      @handle = handle
      @name = name
      @github_username = params[:github_username]
      @email = params[:email]
      @team = params[:team]
      @notes = params[:notes] || []
      @inactive = params[:inactive] || false
    end

    # Returns true if the person is active (not inactive).
    # If not specified, persons are active by default.
    # @return [Boolean] true if active, false otherwise
    def active?
      !@inactive
    end

    # Returns true if the person is marked as inactive.
    # @return [Boolean] true if inactive, false otherwise
    def inactive?
      @inactive
    end

    # Creates a new Person instance from a hash of attributes.
    # @param hash [Hash] A hash containing person attributes
    # @option hash [String] :handle The person's handle (username)
    # @option hash [String] :name The person's full name
    # @option hash [String, nil] :email The person's email address, can be nil
    # @option hash [String, nil] :team The team the person belongs to, can be nil
    # @option hash [Array<String>] :notes An array of notes about the person
    # @return [Person] A new Person instance
    def self.from_hash(hash)
      hash = hash.transform_keys(&:to_sym)

      raise ArgumentError, 'Person handle is required' unless hash[:handle]
      raise ArgumentError, 'Person name is required' unless hash[:name]

      handle = hash[:handle]
      name = hash[:name]
      Person.new(handle: handle, name: name, **hash)
    end

    def to_s
      return "#{name} (~#{handle})" if @email.nil?

      "#{name} (~#{handle}) <#{email}>"
    end

    def ==(other)
      return false unless other.is_a?(Person)

      handle == other.handle && name == other.name && email == other.email && team == other.team && notes == other.notes
    end
  end
end
