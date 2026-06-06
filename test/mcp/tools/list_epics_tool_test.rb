# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require_relative '../../test_helper'
require_relative '../mcp_test_helper'

require 'mcp/tools/list_epics_tool'

class ListEpicsToolTest < Minitest::Test
  include McpTestHelper

  def setup
    setup_mcp_context
    @tool = Worklog::Mcp::ListEpicsTool.new
  end

  def teardown
    teardown_mcp_context
  end

  def test_list_all_epics
    result = JSON.parse(@tool.call)

    assert_equal 1, result['total_count']
    assert result['epics'].first['epic']
  end

  def test_epics_with_date_range
    result = JSON.parse(@tool.call(from: '2024-03-16', to: '2024-03-16'))

    assert_equal 0, result['total_count']
    assert_empty result['epics']
  end

  def test_epics_by_project
    result = JSON.parse(@tool.call(project: 'auth'))

    assert_equal 1, result['total_count']

    result2 = JSON.parse(@tool.call(project: 'docs'))

    assert_equal 0, result2['total_count']
  end

  def test_epic_entry_fields
    result = JSON.parse(@tool.call)
    epic = result['epics'].first

    assert epic['epic']
    refute_nil epic['date']
    refute_nil epic['message']
  end
end
