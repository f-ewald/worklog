# frozen_string_literal: true

require 'json'
require 'log_entry_formatters'

module Worklog
  module Mcp
    # Shared JSON serialization for MCP tool responses.
    # Converts DailyLog arrays into JSON-friendly hashes using SimpleFormatter
    # for clean message text without ANSI colors.
    module EntrySerializer
      # Serialize an array of DailyLog objects into a JSON-friendly array.
      #
      # @param daily_logs [Array<DailyLog>] The daily logs to serialize
      # @param people [Hash<String, Person>, nil] Known people for handle resolution
      # @return [Array<Hash>] Serialized daily logs with entries
      def serialize_daily_logs(daily_logs, people = nil)
        formatter = LogEntryFormatters::SimpleFormatter.new(people)
        daily_logs.map do |daily_log|
          {
            date: daily_log.date.to_s,
            entries: daily_log.entries.map { |e| serialize_entry(e, formatter) }
          }
        end
      end

      # Serialize a single LogEntry into a JSON-friendly hash.
      #
      # @param entry [LogEntry] The entry to serialize
      # @param formatter [LogEntryFormatters::SimpleFormatter] Formatter for message text
      # @return [Hash] Serialized entry
      def serialize_entry(entry, formatter)
        {
          time: entry.time.respond_to?(:strftime) ? entry.time.strftime('%H:%M') : entry.time.to_s,
          message: formatter.format(entry),
          tags: entry.tags || [],
          ticket: entry.ticket,
          url: entry.url && entry.url != '' ? entry.url : nil,
          epic: entry.epic == true,
          project: entry.project && entry.project != '' ? entry.project : nil,
          source: entry.source
        }.compact
      end

      # Flatten daily logs into a flat array of entries with date attached.
      #
      # @param daily_logs [Array<DailyLog>] The daily logs to flatten
      # @param people [Hash<String, Person>, nil] Known people for handle resolution
      # @return [Array<Hash>] Flat array of entry hashes with date field
      def flatten_entries(daily_logs, people = nil)
        formatter = LogEntryFormatters::SimpleFormatter.new(people)
        daily_logs.flat_map do |daily_log|
          daily_log.entries.map do |entry|
            serialize_entry(entry, formatter).merge(date: daily_log.date.to_s)
          end
        end
      end
    end
  end
end
