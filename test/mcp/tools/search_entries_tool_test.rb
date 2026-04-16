# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require_relative '../../test_helper'
require_relative '../mcp_test_helper'

require 'mcp/tools/search_entries_tool'

class SearchEntriesToolTest < Minitest::Test
  include McpTestHelper

  def setup
    setup_mcp_context
    @tool = Worklog::Mcp::SearchEntriesTool.new
  end

  def teardown
    teardown_mcp_context
  end

  def test_search_case_insensitive
    result = JSON.parse(@tool.call(query: 'login bug'))

    assert_equal 1, result['total_count']
    assert_includes result['entries'].first['message'].downcase, 'login bug'
  end

  def test_search_no_results
    result = JSON.parse(@tool.call(query: 'nonexistent term'))

    assert_equal 0, result['total_count']
    assert_empty result['entries']
  end

  def test_search_with_date_range
    result = JSON.parse(@tool.call(query: 'auth', from: '2024-03-15', to: '2024-03-15'))

    assert_operator result['total_count'], :>=, 1
    # Should not include day 2 entries
    result['entries'].each do |entry|
      assert_equal '2024-03-15', entry['date']
    end
  end

  def test_search_pagination
    result = JSON.parse(@tool.call(query: 'a', limit: 1, offset: 0))
    first_entry = result['entries'].first

    result2 = JSON.parse(@tool.call(query: 'a', limit: 1, offset: 1))
    second_entry = result2['entries'].first

    # The two pages should return different entries (if total > 1)
    refute_equal first_entry, second_entry if result['total_count'] > 1
  end

  def test_search_includes_query_in_response
    result = JSON.parse(@tool.call(query: 'documentation'))

    assert_equal 'documentation', result['query']
  end
end
