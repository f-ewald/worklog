# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require_relative '../../test_helper'
require_relative '../mcp_test_helper'

require 'mcp/resources/people_resource'

class PeopleResourceTest < Minitest::Test
  include McpTestHelper

  def setup
    setup_mcp_context
    @resource = Worklog::Mcp::PeopleResource.new
  end

  def teardown
    teardown_mcp_context
  end

  def test_content_returns_valid_json
    people = JSON.parse(@resource.content)

    assert_instance_of Array, people
    assert_equal 2, people.size
  end

  def test_find_person_by_handle
    people = JSON.parse(@resource.content)
    jdoe = people.find { |p| p['handle'] == 'jdoe' }

    refute_nil jdoe
  end

  def test_person_identity_fields
    people = JSON.parse(@resource.content)
    jdoe = people.find { |p| p['handle'] == 'jdoe' }

    assert_equal 'Jane Doe', jdoe['name']
    assert_equal 'Platform', jdoe['team']
  end

  def test_person_contact_and_status_fields
    people = JSON.parse(@resource.content)
    jdoe = people.find { |p| p['handle'] == 'jdoe' }

    assert_equal 'jane@example.com', jdoe['email']
    assert jdoe['active']
  end

  def test_inactive_person_included
    people = JSON.parse(@resource.content)
    bob = people.find { |p| p['handle'] == 'bob' }

    refute_nil bob
    refute bob['active']
  end
end
