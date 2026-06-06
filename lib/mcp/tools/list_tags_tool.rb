# frozen_string_literal: true

require 'fast_mcp'

module Worklog
  module Mcp
    # MCP tool to list all tags used in worklog entries with their occurrence counts.
    # Optionally filtered by date range.
    class ListTagsTool < FastMcp::Tool
      include DateHelper

      tool_name 'list_tags'
      description 'List all tags used in worklog entries with their occurrence counts. ' \
                  'Optionally filter by date range.'
      annotations(read_only_hint: true, destructive_hint: false)

      arguments do
        optional(:from).filled(:string).description('Start date (inclusive).')
        optional(:to).filled(:string).description('End date (inclusive).')
      end

      # @param from [String, nil] Start date
      # @param to [String, nil] End date
      # @return [String] JSON with tags array and metadata
      def call(from: nil, to: nil)
        start_date, end_date = resolve_date_range(from: from, to: to)
        daily_logs = McpContext.storage.days_between(start_date, end_date)

        tags = daily_logs.flat_map(&:entries).flat_map(&:tags).compact.tally
        sorted_tags = tags.sort_by { |name, _| name }.map { |name, count| { name: name, count: count } }

        JSON.generate({
                        tags: sorted_tags,
                        total_unique_tags: sorted_tags.size,
                        date_range: { from: start_date.to_s, to: end_date.to_s }
                      })
      end
    end
  end
end
