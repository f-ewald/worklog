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
    "#{name} (~#{handle}) <#{email}>"
  end
end
