# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require_relative '../../test_helper'
require_relative '../mcp_test_helper'

require 'mcp/tools/get_statistics_tool'

class GetStatisticsToolTest < Minitest::Test
  include McpTestHelper

  def setup
    setup_mcp_context
    @tool = Worklog::Mcp::GetStatisticsTool.new
  end

  def teardown
    teardown_mcp_context
  end

  def test_statistics
    result = JSON.parse(@tool.call)

    assert_equal 2, result['total_days']
    assert_equal 3, result['total_entries']
    assert_equal 1, result['total_epics']
    assert_in_delta(1.5, result['avg_entries_per_day'])
    assert_equal '2024-03-15', result['first_entry']
    assert_equal '2024-03-16', result['last_entry']
  end

  def test_all_fields_present
    result = JSON.parse(@tool.call)

    %w[total_days total_entries total_epics avg_entries_per_day first_entry last_entry].each do |field|
      assert result.key?(field), "Missing field: #{field}"
    end
  end
end
