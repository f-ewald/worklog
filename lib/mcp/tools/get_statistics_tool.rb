# frozen_string_literal: true

require 'fast_mcp'
require 'statistics'

module Worklog
  module Mcp
    # MCP tool to get overall worklog statistics.
    # Returns total days, entries, epics, average entries per day, and date range.
    class GetStatisticsTool < FastMcp::Tool
      tool_name 'get_statistics'
      description 'Get overall worklog statistics: total days logged, total entries, ' \
                  'total epics, average entries per day, and the date range of all entries.'
      annotations(read_only_hint: true, destructive_hint: false)

      arguments do
        # No arguments -- returns global stats
      end

      # @return [String] JSON with worklog statistics
      def call
        stats = Statistics.new(McpContext.config).calculate

        JSON.generate({
                        total_days: stats.total_days,
                        total_entries: stats.total_entries,
                        total_epics: stats.total_epics,
                        avg_entries_per_day: stats.avg_entries.round(2),
                        first_entry: stats.first_entry.to_s,
                        last_entry: stats.last_entry.to_s
                      })
      end
    end
  end
end
