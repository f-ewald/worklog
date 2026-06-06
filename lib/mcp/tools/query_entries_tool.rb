# frozen_string_literal: true

require 'fast_mcp'

module Worklog
  module Mcp
    # MCP tool to query worklog entries by date range, tags, epic status, and project.
    # Returns matching log entries as JSON with pagination support.
    class QueryEntriesTool < FastMcp::Tool
      include DateHelper
      include EntrySerializer

      tool_name 'query_entries'
      description 'Query worklog entries by date range, tags, epic status, and project. ' \
                  'Returns matching log entries as JSON. Dates support ISO format (YYYY-MM-DD), ' \
                  'year-month (YYYY-MM), year (YYYY), and quarters (Q1-Q4, YYYY-Q1).'
      annotations(read_only_hint: true, destructive_hint: false)

      arguments do
        optional(:from).filled(:string).description(
          'Start date (inclusive). Formats: YYYY-MM-DD, YYYY-MM, YYYY, Q1-Q4, YYYY-Q1. Defaults to all time.'
        )
        optional(:to).filled(:string).description(
          'End date (inclusive). Same formats as from. Defaults to today.'
        )
        optional(:days).filled(:integer).description(
          'Number of days back from today. Overrides from/to if provided.'
        )
        optional(:tags).description('Filter entries to those having at least one of these tags.').array(:string)
        optional(:epics_only).filled(:bool).description('If true, return only entries marked as epics.')
        optional(:project).filled(:string).description('Filter entries by project key.')
        optional(:limit).filled(:integer).description('Maximum number of entries to return. Default: 100.')
        optional(:offset).filled(:integer).description('Number of entries to skip for pagination. Default: 0.')
      end

      # @param from [String, nil] Start date
      # @param to [String, nil] End date
      # @param days [Integer, nil] Days back from today
      # @param tags [Array<String>, nil] Tag filter
      # @param epics_only [Boolean, nil] Filter to epics only
      # @param project [String, nil] Project key filter
      # @param limit [Integer] Max entries to return
      # @param offset [Integer] Entries to skip
      # @return [String] JSON response with entries and pagination metadata
      def call(from: nil, to: nil, days: nil, tags: nil, epics_only: nil, project: nil, limit: 100, offset: 0) # rubocop:disable Metrics/ParameterLists
        start_date, end_date = resolve_date_range(from: from, to: to, days: days)
        daily_logs = McpContext.storage.days_between(start_date, end_date, epics_only, tags)

        # Filter by project if specified
        if project && !project.empty?
          daily_logs.each do |dl|
            dl.entries.select! { |e| e.project == project }
          end
          daily_logs.reject! { |dl| dl.entries.empty? }
        end

        all_entries = flatten_entries(daily_logs, McpContext.people)
        total_count = all_entries.size
        paginated = all_entries[offset, limit] || []

        JSON.generate({
                        entries: paginated,
                        total_count: total_count,
                        offset: offset,
                        limit: limit,
                        date_range: { from: start_date.to_s, to: end_date.to_s }
                      })
      end
    end
  end
end
