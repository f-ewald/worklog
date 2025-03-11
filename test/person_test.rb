# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'
require_relative '../worklog/person'

class PersonTest < Minitest::Test
  def test_to_s
    person = Person.new('jdoe', 'John Doe', 'john_doe@example.org', 'Engineering', [])
    assert_equal 'John Doe (~jdoe) <john_doe@example.org>', person.to_s
  end
end