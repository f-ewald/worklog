# frozen_string_literal: true

require 'json'
require 'db'
require 'daily_log'
require 'log_entry'
require 'storage/base'
require 'worklogger'

module Worklog
  module Storage
    # Postgres-backed implementation of {Worklog::Storage::Base}. Uses
    # {Worklog::DB.connection} for connection management and stores
    # entries in the `daily_logs` / `log_entries` tables created by the
    # Sequel migrations under `db/migrations/`.
    #
    # When run against a non-Postgres adapter (e.g., SQLite for tests),
    # array columns (`tags`) are serialized as JSON text. The backend
    # transparently handles both representations.
    class Postgres < Base
      def initialize(config)
        super
        @db = ::Worklog::DB.connection(config)
        @uses_native_arrays = @db.database_type == :postgres
      end

      # @return [Array<DailyLog>]
      def all_days
        @db[:daily_logs].order(:date).all.map { |row| load_log_for_date(row[:date]) }.compact
      end

      # @param date [Date]
      # @return [DailyLog, nil]
      def load_log_for_date(date)
        date = coerce_date(date)
        log_row = @db[:daily_logs].where(date: date).first
        return nil unless log_row

        entries = @db[:log_entries].where(daily_log_id: log_row[:id]).order(:time).all.map do |row|
          LogEntry.new(
            key: row[:key],
            source: row[:source] || 'manual',
            time: row[:time],
            tags: deserialize_array(row[:tags]),
            ticket: row[:ticket],
            url: row[:url] || '',
            epic: row[:epic],
            message: row[:message],
            project: row[:project]
          )
        end
        DailyLog.new(date: log_row[:date], entries: entries)
      end

      # Upsert the daily log: ensures a `daily_logs` row exists for the
      # date, then replaces all `log_entries` for that day with the
      # provided ones (sorted by time).
      # @param daily_log [DailyLog]
      # @return [void]
      def save_log(daily_log)
        daily_log.entries.sort_by!(&:time)
        @db.transaction do
          log_id = upsert_daily_log_id(daily_log.date)
          @db[:log_entries].where(daily_log_id: log_id).delete
          daily_log.entries.each do |entry|
            @db[:log_entries].insert(
              daily_log_id: log_id,
              key: entry.key,
              source: entry.source,
              time: entry.time,
              tags: serialize_array(entry.tags),
              ticket: entry.ticket,
              url: entry.url,
              epic: entry.epic == true,
              message: entry.message,
              project: entry.project
            )
          end
        end
      end

      # Logs for the inclusive date range. Overrides the base
      # implementation with a single SQL query for the date scan.
      # @param start_date [Date]
      # @param end_date [Date, nil]
      # @param epics_only [Boolean, nil]
      # @param tags_filter [Array<String>, nil]
      # @return [Array<DailyLog>]
      def days_between(start_date, end_date = nil, epics_only = nil, tags_filter = nil)
        end_date ||= Date.today
        return [] if start_date > end_date

        @db[:daily_logs].where(date: start_date..end_date).order(:date).all.filter_map do |row|
          log = load_log_for_date(row[:date])
          next nil if log.nil?

          log.entries.keep_if(&:epic?) if epics_only
          log.entries.keep_if { |entry| entry.tags&.intersect?(tags_filter) } if tags_filter
          log.entries.empty? ? nil : log
        end
      end

      private

      # Insert a daily_logs row if missing, return its id either way.
      # @param date [Date]
      # @return [Integer]
      def upsert_daily_log_id(date)
        row = @db[:daily_logs].where(date: date).first
        return row[:id] if row

        @db[:daily_logs].insert(date: date)
      end

      # @param value [Array<String>, nil]
      # @return [Array<String>, String, nil]
      def serialize_array(value)
        value = [] if value.nil?
        return value if @uses_native_arrays

        JSON.dump(value)
      end

      # @param value [Array<String>, String, nil]
      # @return [Array<String>]
      def deserialize_array(value)
        return [] if value.nil?
        return value if value.is_a?(Array)

        parsed = JSON.parse(value)
        parsed.is_a?(Array) ? parsed : []
      rescue JSON::ParserError
        []
      end

      # Sequel returns Date objects directly, but callers may pass in
      # a String. Normalize for consistent equality.
      # @param value [Date, String]
      # @return [Date]
      def coerce_date(value)
        return value if value.is_a?(Date)

        Date.parse(value.to_s)
      end
    end
  end
end
