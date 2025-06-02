# frozen_string_literal: true

# Represents a person at work.
class Person
  attr_reader :handle, :name, :email, :team, :notes

  def initialize(handle, name, email, team, notes = [])
    @handle = handle
    @name = name
    @email = email
    @team = team
    @notes = notes
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
