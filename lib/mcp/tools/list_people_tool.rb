# frozen_string_literal: true

require 'fast_mcp'

module Worklog
  module Mcp
    # MCP tool to list people mentioned in worklog entries with their mention counts.
    # People are referenced with ~handle or @handle in entry messages.
    class ListPeopleTool < FastMcp::Tool
      include DateHelper

      tool_name 'list_people'
      description 'List people mentioned in worklog entries with their mention counts. ' \
                  'People are referenced with ~handle or @handle in entry messages.'
      annotations(read_only_hint: true, destructive_hint: false)

      arguments do
        optional(:from).filled(:string).description('Start date (inclusive).')
        optional(:to).filled(:string).description('End date (inclusive).')
        optional(:include_inactive).filled(:bool).description('Include inactive people. Default: false.')
      end

      # @param from [String, nil] Start date
      # @param to [String, nil] End date
      # @param include_inactive [Boolean] Whether to include inactive people
      # @return [String] JSON with people array and mention counts
      def call(from: nil, to: nil, include_inactive: false)
        start_date, end_date = resolve_date_range(from: from, to: to)
        daily_logs = McpContext.storage.days_between(start_date, end_date)
        people_hash = McpContext.people

        # Tally mentions across all daily logs
        mentions = {}
        daily_logs.each do |dl|
          dl.people.each do |handle, count|
            mentions[handle] = (mentions[handle] || 0) + count
          end
        end

        # Build enriched people list
        people_list = mentions.map do |handle, count|
          person = people_hash[handle]
          if person
            next nil if person.inactive? && !include_inactive

            {
              handle: handle,
              name: person.name,
              team: person.team,
              email: person.email,
              mention_count: count,
              active: person.active?
            }.compact
          else
            { handle: handle, mention_count: count }
          end
        end.compact

        # Sort by mention count descending
        people_list.sort_by! { |p| -p[:mention_count] }

        JSON.generate({
                        people: people_list,
                        total_count: people_list.size,
                        date_range: { from: start_date.to_s, to: end_date.to_s }
                      })
      end
    end
  end
end
