# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'

require_relative '../worklog/statistics'

class StatisticsTest < Minitest::Test
  def test_calculate
    refute_nil Statistics.calculate
  end
end