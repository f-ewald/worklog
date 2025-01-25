# frozen_string_literal: true

# Represents a person at work.
class Person
  attr_reader :name, :email, :team, :notes

  def initialize(name, email, team, notes = [])
    @name = name
    @email = email
    @team = team
    @notes = notes
  end

  def to_s
    "#{name} <#{email}>"
  end
end
