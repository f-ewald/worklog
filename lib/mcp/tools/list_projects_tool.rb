# frozen_string_literal: true

require 'fast_mcp'

module Worklog
  module Mcp
    # MCP tool to list all defined projects with their metadata.
    # Optionally filter by project status.
    class ListProjectsTool < FastMcp::Tool
      tool_name 'list_projects'
      description 'List all defined projects with their metadata and recent activity.'
      annotations(read_only_hint: true, destructive_hint: false)

      arguments do
        optional(:status).filled(:string).description(
          "Filter by project status (e.g., 'active', 'completed', 'archived')."
        )
      end

      # @param status [String, nil] Filter by project status
      # @return [String] JSON with projects array
      def call(status: nil)
        projects = McpContext.project_storage.load_projects

        # Compute entry counts and last activity from logs
        all_days = McpContext.storage.all_days
        project_entries = Hash.new { |h, k| h[k] = { count: 0, last_activity: nil } }

        all_days.each do |daily_log|
          daily_log.entries.each do |entry|
            next unless entry.project && projects.key?(entry.project)

            data = project_entries[entry.project]
            data[:count] += 1
            data[:last_activity] = entry.time if data[:last_activity].nil? || entry.time > data[:last_activity]
          end
        end

        project_list = projects.values.map do |project|
          next if status && project.status != status

          data = project_entries[project.key]
          {
            key: project.key,
            name: project.name,
            description: project.description,
            status: project.status,
            start_date: project.start_date&.to_s,
            end_date: project.end_date&.to_s,
            entry_count: data[:count],
            last_activity: data[:last_activity]&.strftime('%Y-%m-%d')
          }.compact
        end.compact

        JSON.generate({ projects: project_list, total_count: project_list.size })
      end
    end
  end
end
