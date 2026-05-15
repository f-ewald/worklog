# frozen_string_literal: true

require 'tty-prompt'
require 'yaml'
require 'editor'
require 'log_entry'
require 'log_entry_formatters'

module Worklog
  # Interactive editor for selecting and editing individual log entries.
  module InteractiveEditor
    # Display an interactive menu to select an entry from a daily log.
    # @param daily_log [DailyLog] the daily log containing entries.
    # @param people [Hash<String, Person>] A hash of people with their handles as keys.
    # @return [LogEntry, nil] the selected entry or nil if cancelled.
    def self.select_entry(daily_log, people)
      prompt = TTY::Prompt.new

      # Format entries for display: "HH:MM - message text"
      formatter = LogEntryFormatters::SimpleFormatter.new(people)
      choices = daily_log.entries.map do |entry|
        time_str = entry.time.strftime('%H:%M')
        message_str = formatter.format(entry)
        {
          name: "#{time_str} - #{message_str}",
          value: entry
        }
      end

      # Add cancel option at the bottom
      choices << { name: '(Cancel)', value: nil }

      prompt.select(
        'Select an entry to edit:',
        choices,
        per_page: 15,
        cycle: true
      )
    end

    # Open an editor for a single entry and return the updated entry.
    # @param entry [LogEntry] the entry to edit.
    # @return [LogEntry, nil] the updated entry or nil if cancelled or failed.
    def self.edit_entry(entry)
      # Convert entry to hash and then to YAML
      entry_hash = entry.to_hash
      entry_yaml = YAML.dump(entry_hash)

      # Prepare content with editor preamble
      txt = Editor::EDITOR_PREAMBLE.result_with_hash(content: entry_yaml)

      # Open editor
      updated_text = Editor.open_editor(txt)

      # Parse the updated YAML
      begin
        # Remove the comment lines from the editor preamble
        cleaned_text = updated_text.lines.reject { |line| line.strip.start_with?('#') }.join
        updated_hash = YAML.safe_load(cleaned_text, permitted_classes: [Time, Symbol], symbolize_names: true)

        # Return nil if nothing changed
        if updated_hash == entry_hash
          WorkLogger.debug('No changes detected in edited entry')
          return nil
        end

        # Create new LogEntry from updated hash
        LogEntry.from_hash(updated_hash)
      rescue Psych::SyntaxError => e
        WorkLogger.error "Failed to parse edited entry: #{e.message}"
        nil
      end
    end
  end
end
