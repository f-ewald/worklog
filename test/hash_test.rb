# frozen_string_literal: true

require 'minitest/autorun'
require 'test_helper'
require 'hash'

class HashTest < Minitest::Test
  def setup
    @hash = Hash.new
  end

  def test_to_hash
    test_class = Class.new do
      include Hashify

      attr_accessor :a, :b

      def initialize(a, b)
        @a = a
        @b = b
      end
    end

    obj = test_class.new(1, 'test')
    expected_hash = { a: 1, b: 'test' }
    assert_equal(expected_hash, obj.to_hash)
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
