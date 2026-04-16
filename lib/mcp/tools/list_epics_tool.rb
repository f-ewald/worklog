# frozen_string_literal: true

require 'fast_mcp'

module Worklog
  module Mcp
    # MCP tool to list all entries marked as epics.
    # Epics represent significant achievements or milestones.
    class ListEpicsTool < FastMcp::Tool
      include DateHelper
      include EntrySerializer

      tool_name 'list_epics'
      description 'List all entries marked as epics. Epics represent significant achievements or milestones. ' \
                  'Optionally filter by date range and project.'
      annotations(read_only_hint: true, destructive_hint: false)

      arguments do
        optional(:from).filled(:string).description('Start date (inclusive).')
        optional(:to).filled(:string).description('End date (inclusive).')
        optional(:project).filled(:string).description('Filter epics by project key.')
      end

      # @param from [String, nil] Start date
      # @param to [String, nil] End date
      # @param project [String, nil] Project key filter
      # @return [String] JSON with epic entries
      def call(from: nil, to: nil, project: nil)
        start_date, end_date = resolve_date_range(from: from, to: to)
        daily_logs = McpContext.storage.days_between(start_date, end_date, true)

        if project && !project.empty?
          daily_logs.each { |dl| dl.entries.select! { |e| e.project == project } }
          daily_logs.reject! { |dl| dl.entries.empty? }
        end

        entries = flatten_entries(daily_logs, McpContext.people)

        JSON.generate({
                        epics: entries,
                        total_count: entries.size,
                        date_range: { from: start_date.to_s, to: end_date.to_s }
                      })
      end
    end
  end
end
