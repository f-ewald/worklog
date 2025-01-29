# frozen_string_literal: true

require 'date'

module DateParser
  # Best effort date parsing from multiple formats.
  def self.parse_date_string(date_str, from_beginning = true)
    return nil if date_str.nil?
    return nil if date_str.empty?
    return nil if date_str.length > 10

    # Try to parse basic format YYYY-MM-DD
    begin
      return Date.strptime(date_str, '%Y-%m-%d') if date_str.match(/^\d{4}-\d{1,2}-\d{1,2}$/)
    rescue Date::Error
      # puts "Date not in format YYYY-MM-DD."
    end

    # Try to parse format YYYY-MM
    begin
      if date_str.match(/^\d{4}-\d{1,2}$/)
        d = Date.strptime(date_str, '%Y-%m')
        if from_beginning
          return d
        else
          return Date.new(d.year, d.month, -1)
        end
      end
    rescue Date::Error
      # puts "Date not in format YYYY-MM."
    end

    # Try to parse format YYYY (without Q1234)
    if date_str.match(/^\d{4}$/)
      d = Date.strptime(date_str, '%Y')
      if from_beginning
        return d
      else
        return Date.new(d.year, -1, -1)
      end
    end

    # Long form quarter (2024-Q1, etc.)
    match = date_str.match(/(\d{4})-[qQ]([1234])/)
    if match
      year, quarter = match.captures.map(&:to_i)
      d = Date.new(year, ((quarter - 1) * 3) + 1, 1)
      if from_beginning
        return d
      else
        return Date.new(d.year, d.month + 2, -1)
      end
    end

    # Short form quarter
    match = date_str.match(/[qQ]([1234])/)
    if match
      quarter = match.captures.first.to_i
      d = Date.new(Date.today.year, ((quarter - 1) * 3) + 1, 1)
      if from_beginning
        return d
      else
        return Date.new(d.year, d.month + 2, -1)
      end
    end
  end

  def self.parse_date_string!(date_str, from_beginning = true)
    date = parse_date_string(date_str, from_beginning)
    raise ArgumentError, "Could not parse date string: \"#{date_str}\"" if date.nil?

    date
  end
end
