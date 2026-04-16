# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require_relative '../../test_helper'
require_relative '../mcp_test_helper'

require 'mcp/tools/query_entries_tool'

class QueryEntriesToolTest < Minitest::Test
  include McpTestHelper

  def setup
    setup_mcp_context
    @tool = Worklog::Mcp::QueryEntriesTool.new
  end

  def teardown
    teardown_mcp_context
  end

  def test_query_by_date_range
    result = JSON.parse(@tool.call(from: '2024-03-15', to: '2024-03-15'))

    assert_equal 2, result['total_count']
    assert_equal 2, result['entries'].size
  end

  def test_query_multiple_days
    result = JSON.parse(@tool.call(from: '2024-03-15', to: '2024-03-16'))

    assert_equal 3, result['total_count']
  end

  def test_query_empty_range
    result = JSON.parse(@tool.call(from: '2025-01-01', to: '2025-01-01'))

    assert_equal 0, result['total_count']
    assert_empty result['entries']
  end

  def test_query_epics_only
    result = JSON.parse(@tool.call(from: '2024-03-15', to: '2024-03-16', epics_only: true))

    assert_equal 1, result['total_count']
    assert(result['entries'].all? { |e| e['epic'] })
  end

  def test_query_by_tags
    result = JSON.parse(@tool.call(from: '2024-03-15', to: '2024-03-16', tags: ['bugfix']))

    assert_equal 1, result['total_count']
    assert_includes result['entries'].first['tags'], 'bugfix'
  end

  def test_query_by_project
    result = JSON.parse(@tool.call(from: '2024-03-15', to: '2024-03-16', project: 'docs'))

    assert_equal 1, result['total_count']
    assert_equal 'docs', result['entries'].first['project']
  end

  def test_query_with_days
    # This will query from (today - 0) to today, which shouldn't match our 2024 data
    result = JSON.parse(@tool.call(days: 0))

    assert_equal 0, result['total_count']
  end

  def test_pagination_limit
    result = JSON.parse(@tool.call(from: '2024-03-15', to: '2024-03-16', limit: 1))

    assert_equal 3, result['total_count']
    assert_equal 1, result['entries'].size
    assert_equal 0, result['offset']
    assert_equal 1, result['limit']
  end

  def test_pagination_offset
    result = JSON.parse(@tool.call(from: '2024-03-15', to: '2024-03-16', limit: 1, offset: 2))

    assert_equal 3, result['total_count']
    assert_equal 1, result['entries'].size
  end

  def test_date_range_in_response
    result = JSON.parse(@tool.call(from: '2024-03-15', to: '2024-03-16'))

    assert_equal '2024-03-15', result['date_range']['from']
    assert_equal '2024-03-16', result['date_range']['to']
  end

  def test_entry_fields
    result = JSON.parse(@tool.call(from: '2024-03-15', to: '2024-03-15'))
    entry = result['entries'].find { |e| e['ticket'] == 'AUTH-456' }

    refute_nil entry
    assert_equal 'bugfix', entry['tags'].first
    assert_equal 'https://github.com/example/pr/1', entry['url']
    assert_equal 'auth', entry['project']
    assert_equal 'github', entry['source']
    assert_equal false, entry['epic']
  end
end
