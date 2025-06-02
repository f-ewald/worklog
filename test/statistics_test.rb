# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'

require 'configuration'
require 'statistics'

class StatisticsTest < Minitest::Test
  def setup
    @config = Configuration.new do |cfg|
      cfg.storage_path = File.join(Dir.tmpdir, 'worklog_test')
    end
    @statistics = Statistics.new(@config)
  end

  def test_calculate
    refute_nil @statistics.calculate
  end
end