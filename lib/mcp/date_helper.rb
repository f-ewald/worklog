# frozen_string_literal: true

require 'date'
require 'date_parser'

module Worklog
  module Mcp
    # Shared date range resolution for MCP tools.
    # Converts from/to/days parameters into a [start_date, end_date] pair
    # using the existing DateParser for flexible date format support.
    module DateHelper
      # Resolve a date range from MCP tool arguments.
      #
      # @param from [String, nil] Start date string (supports YYYY-MM-DD, YYYY-MM, YYYY, Q1-Q4, YYYY-Q1)
      # @param to [String, nil] End date string (same formats)
      # @param days [Integer, nil] Number of days back from today (overrides from/to)
      # @return [Array(Date, Date)] The resolved [start_date, end_date] pair
      def resolve_date_range(from: nil, to: nil, days: nil)
        if days
          start_date = Date.today - days
          end_date = Date.today
        elsif from || to
          start_date = from ? DateParser.parse_date_string!(from, true) : ::Worklog::Worklog::EARLIEST_START_DATE
          end_date = to ? DateParser.parse_date_string!(to, false) : Date.today
        else
          start_date = ::Worklog::Worklog::EARLIEST_START_DATE
          end_date = Date.today
        end
        [start_date, end_date]
      end
    end
  end
end
