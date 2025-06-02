# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'
require 'string_helper'

class StringHelperTest < Minitest::Test
  def setup
    @helper = Object.new
    @helper.extend(StringHelper)
  end

  def test_pluralize
    assert_equal 'apple', @helper.pluralize(1, 'apple')
    assert_equal 'apples', @helper.pluralize(2, 'apple')
    assert_equal 'apples', @helper.pluralize(3, 'apple')
    assert_equal 'apples', @helper.pluralize(0, 'apple')
    assert_equal 'bananas', @helper.pluralize(0, 'apple', 'bananas')

    assert_equal 'cherry', @helper.pluralize(1, 'cherry')
    assert_equal 'cherries', @helper.pluralize(2, 'cherry')
    assert_equal 'leaves', @helper.pluralize(2, 'leaf')

    assert_equal 'duty', @helper.pluralize(1, 'duty')
    assert_equal 'duties', @helper.pluralize(2, 'duty')

    assert_equal 'peach', @helper.pluralize(1, 'peach')
    assert_equal 'peaches', @helper.pluralize(2, 'peach')
  end

  def test_format_left
    assert_equal '              test', @helper.format_left('test')
    assert_equal '                  ', @helper.format_left('')
    assert_equal '123456789012345678', @helper.format_left('123456789012345678')
    assert_equal '1234567890123456789', @helper.format_left('1234567890123456789')
  end
end