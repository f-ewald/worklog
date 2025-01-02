# frozen_string_literal: true
require 'daily_log'
require 'hash'
require 'yaml'


# A single log entry.
class LogEntry
  include Hashify

  # Represents a single entry in the work log.
  attr_accessor :time, :tags, :ticket, :epic, :message

  def initialize(time, tags, ticket, epic, message)
    @time = time
    @tags = tags
    @ticket = ticket
    @epic = epic
    @message = message
  end

  # Returns true if the entry is an epic, false otherwise.
  def epic?
    @epic == true
  end

  # Returns the message string with formatting without the time.
  def message_string
    s = ''

    if epic
      s += Rainbow("[EPIC] #{@message}").bg(:white).fg(:black)
    else
      s += message
    end

    if @ticket
      s += "  [#{Rainbow(@ticket).fg(:blue)}]"
    end

    if @tags && @tags.size > 0
      s += "  [" + @tags.map { |tag| "#{tag}" }.join(', ') + "]"
    end

    s
  end

  def to_yaml
    to_hash.to_yaml
  end
end
