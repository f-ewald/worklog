# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require_relative '../../test_helper'
require_relative '../mcp_test_helper'

require 'mcp/tools/list_projects_tool'

class ListProjectsToolTest < Minitest::Test
  include McpTestHelper

  def setup
    setup_mcp_context
    @tool = Worklog::Mcp::ListProjectsTool.new
  end

  def teardown
    teardown_mcp_context
  end

  def test_list_all_projects
    result = JSON.parse(@tool.call)

    assert_equal 2, result['total_count']
    keys = result['projects'].map { |p| p['key'] }

    assert_includes keys, 'auth'
    assert_includes keys, 'docs'
  end

  def test_filter_by_status
    result = JSON.parse(@tool.call(status: 'active'))

    assert_equal 1, result['total_count']
    assert_equal 'auth', result['projects'].first['key']
  end

  def test_filter_by_status_no_match
    result = JSON.parse(@tool.call(status: 'archived'))

    assert_equal 0, result['total_count']
  end

  def test_project_entry_counts
    result = JSON.parse(@tool.call)
    auth_project = result['projects'].find { |p| p['key'] == 'auth' }

    assert_equal 2, auth_project['entry_count']

    docs_project = result['projects'].find { |p| p['key'] == 'docs' }

    assert_equal 1, docs_project['entry_count']
  end

  def test_project_metadata
    result = JSON.parse(@tool.call)
    auth_project = result['projects'].find { |p| p['key'] == 'auth' }

    assert_equal 'Auth Refactor', auth_project['name']
    assert_equal 'Refactoring auth', auth_project['description']
    assert_equal 'active', auth_project['status']
  end

  def test_last_activity
    result = JSON.parse(@tool.call)
    auth_project = result['projects'].find { |p| p['key'] == 'auth' }

    refute_nil auth_project['last_activity']
  end
end
