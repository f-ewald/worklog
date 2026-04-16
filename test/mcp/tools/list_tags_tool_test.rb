# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require_relative '../../test_helper'
require_relative '../mcp_test_helper'

require 'mcp/tools/list_tags_tool'

class ListTagsToolTest < Minitest::Test
  include McpTestHelper

  def setup
    setup_mcp_context
    @tool = Worklog::Mcp::ListTagsTool.new
  end

  def teardown
    teardown_mcp_context
  end

  def test_list_all_tags
    result = JSON.parse(@tool.call)
    tags = result['tags']
    tag_names = tags.map { |t| t['name'] }

    assert_includes tag_names, 'code-review'
    assert_includes tag_names, 'auth'
    assert_includes tag_names, 'bugfix'
    assert_includes tag_names, 'docs'
    assert_equal 4, result['total_unique_tags']
  end

  def test_tags_sorted_alphabetically
    result = JSON.parse(@tool.call)
    tag_names = result['tags'].map { |t| t['name'] }

    assert_equal tag_names.sort, tag_names
  end

  def test_tag_counts
    result = JSON.parse(@tool.call)
    auth_tag = result['tags'].find { |t| t['name'] == 'auth' }

    assert_equal 1, auth_tag['count']
  end

  def test_tags_with_date_range
    result = JSON.parse(@tool.call(from: '2024-03-16', to: '2024-03-16'))
    tag_names = result['tags'].map { |t| t['name'] }

    assert_includes tag_names, 'docs'
    refute_includes tag_names, 'bugfix'
  end

  def test_date_range_in_response
    result = JSON.parse(@tool.call(from: '2024-03', to: '2024-03'))

    refute_nil result['date_range']
  end
end
