# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'

require 'statistics'

class StatisticsTest < Minitest::Test
  def setup
    @statistics = Statistics.new(configuration_helper)
  end

  def test_calculate
    refute_nil @statistics.calculate
  end
end