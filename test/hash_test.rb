# frozen_string_literal: true

require 'minitest/autorun'
require 'test_helper'
require_relative '../worklog/hash'

class HashTest < Minitest::Test
  def setup
    @hash = Hash.new
  end

  def test_stringify_keys
    hash = { 'a' => 1, 'b' => 2 }
    assert_equal({ 'a' => 1, 'b' => 2 }, hash.stringify_keys)

    @hash[:a] = 1
    @hash[:b] = 2
    assert_equal({ 'a' => 1, 'b' => 2 }, @hash.stringify_keys)

    @hash[9] = 3
    assert_equal({ 'a' => 1, 'b' => 2, '9' => 3 }, @hash.stringify_keys)
  end
end
