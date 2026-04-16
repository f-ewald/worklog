# frozen_string_literal: true

require 'fast_mcp'
require 'json'

module Worklog
  module Mcp
    # MCP resource exposing the projects list.
    # Returns all projects from projects.yaml as JSON for LLM context.
    class ProjectsResource < FastMcp::Resource
      uri 'worklog:///projects'
      resource_name 'Projects List'
      description 'All projects defined in the worklog with their keys, names, descriptions, and status.'
      mime_type 'application/json'

      # @return [String] JSON array of all projects
      def content
        projects = McpContext.project_storage.load_projects
        project_list = projects.values.map do |project|
          {
            key: project.key,
            name: project.name,
            description: project.description,
            status: project.status,
            start_date: project.start_date&.to_s,
            end_date: project.end_date&.to_s,
            repositories: project.repositories&.map(&:to_s)
          }.compact
        end
        JSON.generate(project_list)
      end
    end
  end
end
