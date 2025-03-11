# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'
require_relative '../worklog/string_helper'

class StringHelperTest < Minitest::Test
  def test_pluralize
    assert_equal 'apple', StringHelper.pluralize(1, 'apple')
    assert_equal 'apples', StringHelper.pluralize(2, 'apple')
    assert_equal 'apples', StringHelper.pluralize(3, 'apple')
    assert_equal 'apples', StringHelper.pluralize(0, 'apple')
    assert_equal 'bananas', StringHelper.pluralize(0, 'apple', 'bananas')

    assert_equal 'cherry', StringHelper.pluralize(1, 'cherry')
    assert_equal 'cherries', StringHelper.pluralize(2, 'cherry')
    assert_equal 'leaves', StringHelper.pluralize(2, 'leaf')

    assert_equal 'duty', StringHelper.pluralize(1, 'duty')
    assert_equal 'duties', StringHelper.pluralize(2, 'duty')

    assert_equal 'peach', StringHelper.pluralize(1, 'peach')
    assert_equal 'peaches', StringHelper.pluralize(2, 'peach')
  end
end