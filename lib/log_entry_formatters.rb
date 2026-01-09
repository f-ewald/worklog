# frozen_string_literal: true

require 'rainbow'

module Worklog
  module LogEntryFormatters
    # The base formatter provides common functionality and prints the message including
    # the metadata (ticket, tags, url, project) in a formatted way. It also replaces
    # people handles with their names if known.
    class BaseFormatter
      # Constructor
      # @param known_people [Hash<String, Person>] A hash of people with their handles as keys.
      def initialize(known_people = nil)
        @known_people = known_people
      end

      # Format the log entry message with metadata.
      # @param log_entry [LogEntry] the log entry to format.
      # @return [String] the formatted message.
      def format(log_entry)
        # replace all mentions of people with their names.
        msg = log_entry.message.dup
        s = String.new
        s << epic_prefix if log_entry.epic
        s << replace_people_handles(log_entry, msg)
        # Add a space between the message and the metadata if there is any metadata to add.
        s << ' ' unless metadata(log_entry).empty?
        s << metadata(log_entry)
        s
      end

      protected

      # Prefix for epic entries.
      # @return [String]
      def epic_prefix
        '⭐️ '
      end

      # Format metadata for display and add some emojis for prettier visualization.
      # @return [String] Formatted metadata
      def metadata(log_entry)
        metadata_parts = []
        metadata_parts << "🎫#{Rainbow(log_entry.ticket).fg(:blue)}" if log_entry.ticket
        metadata_parts << "🏷️#{log_entry.tags.join(', ')}" if log_entry.tags&.any?
        metadata_parts << "🔗#{log_entry.url}" if log_entry.url && log_entry.url != ''
        metadata_parts << "📘#{log_entry.project}" if log_entry.project && log_entry.project != ''

        metadata_parts.empty? ? '' : metadata_parts.join(' ')
      end

      # Replace people handles in the message with their names.
      # @param known_people Hash[String, Person] A hash of people with their handles as keys.
      # @param msg [String] the message to replace handles in.
      # @return [String] the message with replaced handles.
      def replace_people_handles(log_entry, msg)
        log_entry.people.each do |person|
          next unless @known_people && @known_people[person]

          msg.gsub!(/[~@]#{person}/) do |match|
            s = String.new
            s << ' ' if match[0] == ' '
            if @known_people && @known_people[person]
              s << "#{Rainbow(@known_people[person].name).underline} (~#{person})"
            end
            s
          end
        end
        msg
      end
    end

    # Formatter for console output. It adds colors and formatting to the message.
    # It also adds emojis for tickets, tags, urls, and projects.
    # This formatter should be used instead of the BaseFormatter when outputting to the console.
    class ConsoleFormatter < BaseFormatter; end

    # Simple formatter that doesn't add any colors or metadata to the output.
    # This formatter should be used when the output is meant to be consumed by other tools or
    # when the formatting is not desired.
    class SimpleFormatter < BaseFormatter
      # Format the log entry message without any metadata.
      # @param log_entry [LogEntry] the log entry to format.
      # @return [String] the formatted message.
      def format(log_entry)
        replace_people_handles(log_entry, log_entry.message.dup)
      end

      protected

      # Replace people handles in the message with their names.
      # @param known_people Hash[String, Person] A hash of people with their handles as keys.
      # @param msg [String] the message to replace handles in.
      # @return [String] the message with replaced handles.
      def replace_people_handles(log_entry, msg)
        log_entry.people.each do |person|
          next unless @known_people && @known_people[person]

          msg.gsub!(/[~@]#{person}/) do |match|
            s = String.new
            s << ' ' if match[0] == ' '
            s << @known_people[person].name if @known_people && @known_people[person]
            s
          end
        end
        msg
      end
    end
  end
end
