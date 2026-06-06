# frozen_string_literal: true

require 'fast_mcp'

module Worklog
  module Mcp
    # MCP tool to perform full-text search across all worklog entry messages.
    # Supports case-insensitive substring matching with optional date range filtering.
    class SearchEntriesTool < FastMcp::Tool
      include DateHelper
      include EntrySerializer

      tool_name 'search_entries'
      description 'Search worklog entries by text. Performs case-insensitive search ' \
                  'across all entry messages. Optionally limit to a date range.'
      annotations(read_only_hint: true, destructive_hint: false)

      arguments do
        required(:query).filled(:string).description('Search text (case-insensitive substring match).')
        optional(:from).filled(:string).description('Start date (inclusive). Defaults to all time.')
        optional(:to).filled(:string).description('End date (inclusive). Defaults to today.')
        optional(:limit).filled(:integer).description('Maximum number of entries to return. Default: 50.')
        optional(:offset).filled(:integer).description('Number of entries to skip for pagination. Default: 0.')
      end

      # @param query [String] Search text
      # @param from [String, nil] Start date
      # @param to [String, nil] End date
      # @param limit [Integer] Max entries to return
      # @param offset [Integer] Entries to skip
      # @return [String] JSON response with matching entries and pagination metadata
      def call(query:, from: nil, to: nil, limit: 50, offset: 0)
        start_date, end_date = resolve_date_range(from: from, to: to)
        daily_logs = McpContext.storage.days_between(start_date, end_date)

        query_lower = query.downcase
        matching_entries = flatten_entries(daily_logs, McpContext.people).select do |entry|
          entry[:message].downcase.include?(query_lower)
        end

        total_count = matching_entries.size
        paginated = matching_entries[offset, limit] || []

        JSON.generate({
                        entries: paginated,
                        query: query,
                        total_count: total_count,
                        offset: offset,
                        limit: limit,
                        date_range: { from: start_date.to_s, to: end_date.to_s }
                      })
      end
    end
  end
end
