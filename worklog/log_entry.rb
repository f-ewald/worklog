# frozen_string_literal: true

require 'yaml'
require 'rainbow'
require_relative 'daily_log'
require_relative 'hash'

# A single log entry.
class LogEntry
  PERSON_REGEX = /\s[~@](\w+)/

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
  # @param people Hash[String, Person] A hash of people with their handles as keys.
  def message_string(known_people = nil)
    # replace all mentions of people with their names.
    msg = @message.dup
    people.each do |person|
      next unless known_people && known_people[person]

      msg.gsub!(/[~@]#{person}/) do |match|
        s = ''
        s += ' ' if match[0] == ' '
        s += "#{Rainbow(known_people[person].name).underline} (~#{person})" if known_people && known_people[person]
        s
      end
    end

    s = ''

    s += if epic
           Rainbow("[EPIC] #{msg}").bg(:white).fg(:black)
         else
           msg
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
    @message.scan(PERSON_REGEX).flatten.uniq.sort
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
