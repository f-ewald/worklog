# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require_relative '../../test_helper'
require_relative '../mcp_test_helper'

require 'mcp/tools/list_people_tool'

class ListPeopleToolTest < Minitest::Test
  include McpTestHelper

  def setup
    setup_mcp_context
    @tool = Worklog::Mcp::ListPeopleTool.new
  end

  def teardown
    teardown_mcp_context
  end

  def test_list_active_people
    result = JSON.parse(@tool.call)
    handles = result['people'].map { |p| p['handle'] }

    # jdoe is active, bob is inactive (excluded by default)
    assert_includes handles, 'jdoe'
    refute_includes handles, 'bob'
  end

  def test_include_inactive
    result = JSON.parse(@tool.call(include_inactive: true))
    handles = result['people'].map { |p| p['handle'] }

    assert_includes handles, 'jdoe'
    assert_includes handles, 'bob'
  end

  def test_people_enrichment
    result = JSON.parse(@tool.call)
    jdoe = result['people'].find { |p| p['handle'] == 'jdoe' }
    refute_nil jdoe
    assert_equal 'Jane Doe', jdoe['name']
    assert_equal 'Platform', jdoe['team']
    assert jdoe['active']
  end

  def test_mention_counts
    result = JSON.parse(@tool.call)
    jdoe = result['people'].find { |p| p['handle'] == 'jdoe' }
    assert_equal 1, jdoe['mention_count']
  end

  def test_people_with_date_range
    result = JSON.parse(@tool.call(from: '2024-03-16', to: '2024-03-16'))
    handles = result['people'].map { |p| p['handle'] }
    # Only day 2 has ~bob mention, but bob is inactive
    refute_includes handles, 'jdoe'
  end

  def test_sorted_by_mention_count
    result = JSON.parse(@tool.call(include_inactive: true))
    counts = result['people'].map { |p| p['mention_count'] }
    assert_equal counts.sort.reverse, counts
  end
end
