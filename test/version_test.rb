# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'
require 'version'

class VersionTest < Minitest::Test
  def test_current_version
    refute_empty current_version
  end

  def test_increment_version
    assert_equal '1.2.4', increment_version('1.2.3')
    assert_equal '1.3.0', increment_version('1.2.3', 'minor')
    assert_equal '2.0.0', increment_version('1.2.3', 'major')
  end

  def test_increment_version_with_invalid_part
    assert_raises(ArgumentError) do
      increment_version('1.2.3', 'invalid')
    end
  end

  def test_increment_version_with_empty_version
    assert_raises(ArgumentError) do
      increment_version('', 'patch')
    end

    assert_raises(ArgumentError) do
      increment_version(nil, 'patch')
    end

    assert_raises(ArgumentError) do
      increment_version('1.2', 'patch')
    end

    assert_raises(ArgumentError) do
      increment_version('1.2.a', 'patch')
    end
  end
end