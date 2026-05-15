# frozen_string_literal: true

require 'fast_mcp'
require 'json'

module Worklog
  module Mcp
    # MCP resource exposing the people directory.
    # Returns all people from people.yaml as JSON for LLM context.
    class PeopleResource < FastMcp::Resource
      uri 'worklog:///people'
      resource_name 'People Directory'
      description 'All people tracked in the worklog with their handles, names, teams, and status.'
      mime_type 'application/json'

      # @return [String] JSON array of all people
      def content
        people = McpContext.people_storage.load_people
        people_list = people.map do |person|
          {
            handle: person.handle,
            name: person.name,
            team: person.team,
            email: person.email,
            github_username: person.github_username,
            active: person.active?
          }.compact
        end
        JSON.generate(people_list)
      end
    end
  end
end
