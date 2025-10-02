# frozen_string_literal: true

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
class Person
  attr_reader :handle, :name, :email, :team, :notes

  def initialize(handle, name, email, team, notes = [])
    @handle = handle
    @name = name
    @email = email
    @team = team
    @notes = notes
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
    raise ArgumentError, 'Person handle is required' unless hash[:handle] || hash['handle']
    raise ArgumentError, 'Person name is required' unless hash[:name] || hash['name']

    handle = hash[:handle] || hash['handle']
    name = hash[:name] || hash['name']
    email = hash[:email] || hash['email']
    team = hash[:team] || hash['team']
    notes = hash[:notes] || hash['notes'] || []
    Person.new(handle, name, email, team, notes)
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
