# frozen_string_literal: true

require 'yaml'
require 'rainbow'
require_relative 'daily_log'
require_relative 'hash'

# A single log entry.
class LogEntry
  include Hashify

  # Represents a single entry in the work log.
  attr_accessor :time, :tags, :ticket, :url, :epic, :message

  def initialize(params = {})
    @time = params[:time]
    # If tags are nil, set to empty array.
    # This is similar to the CLI default value.
    @tags = params[:tags] || []
    @ticket = params[:ticket]
    @url = params[:url] || ''
    @epic = params[:epic]
    @message = params[:message]
  end

  # Returns true if the entry is an epic, false otherwise.
  def epic?
    @epic == true
  end

  # Returns the message string with formatting without the time.
  def message_string
    s = ''

    s += if epic
           Rainbow("[EPIC] #{@message}").bg(:white).fg(:black)
         else
           message
         end

    s += "  [#{Rainbow(@ticket).fg(:blue)}]" if @ticket

    # Add tags in brackets if defined.
    s += '  [' + @tags.map { |tag| "#{tag}" }.join(', ') + ']' if @tags && @tags.size > 0

    # Add URL in brackets if defined.
    s += "  [#{@url}]" if @url && @url != ''

    s
  end

  def people
    # Return people that are mentioned in the entry.
    # People are defined as words starting with @ or ~.
    # Whitespaces are used to separate people.
    # Punctuation is not considered.
    # Empty array if no people are mentioned.
    #
    # @return [Array<String>]
    @message.scan(/\s[~@](\w+)/).flatten.uniq.sort
  end

  def people?
    # Return true if there are people in the entry.
    #
    # @return [Boolean]
    people.size.positive?
  end

  def to_yaml
    to_hash.to_yaml
  end

  def ==(other)
    time == other.time && tags == other.tags && ticket == other.ticket && url == other.url &&
      epic == other.epic && message == other.message
  end
end
