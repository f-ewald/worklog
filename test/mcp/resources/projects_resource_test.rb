# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require_relative '../../test_helper'
require_relative '../mcp_test_helper'

require 'mcp/resources/projects_resource'

class ProjectsResourceTest < Minitest::Test
  include McpTestHelper

  def setup
    setup_mcp_context
    @resource = Worklog::Mcp::ProjectsResource.new
  end

  def teardown
    teardown_mcp_context
  end

  def test_content_returns_valid_json
    projects = JSON.parse(@resource.content)

    assert_instance_of Array, projects
    assert_equal 2, projects.size
  end

  def test_project_fields
    projects = JSON.parse(@resource.content)
    auth = projects.find { |p| p['key'] == 'auth' }

    refute_nil auth
    assert_equal 'Auth Refactor', auth['name']
    assert_equal 'Refactoring auth', auth['description']
    assert_equal 'active', auth['status']
    assert_equal '2024-01-01', auth['start_date']
  end

  def test_project_without_optional_fields
    projects = JSON.parse(@resource.content)
    docs = projects.find { |p| p['key'] == 'docs' }

    refute_nil docs
    assert_equal 'Documentation', docs['name']
    assert_nil docs['description']
  end
end
