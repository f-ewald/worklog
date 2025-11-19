# frozen_string_literal: true

require_relative 'test_helper'
require 'minitest/autorun'
require 'hasher'

class HasherTest < Minitest::Test
  def test_sha256
    message = 'Test message for hashing'
    expected_hash = Digest::SHA256.hexdigest(message)[..6]
    assert_equal expected_hash, Worklog::Hasher.sha256(message)
  end

  def test_sha256_length
    message = 'Another test message'
    (1..64).each do |length|
      hash = Worklog::Hasher.sha256(message, length)
      assert_equal length, hash.length
    end
  end

  def test_sha256_invalid_length
    message = 'Invalid length test'
    assert_raises(ArgumentError) { Worklog::Hasher.sha256(message, 0) }
    assert_raises(ArgumentError) { Worklog::Hasher.sha256(message, 65) }
  end
end