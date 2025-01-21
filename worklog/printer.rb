# frozen_string_literal: true

require 'rainbow'

# Printer for work log entries
module Printer
  # Prints a whole day of work log entries.
  # If date_inline is true, the date is printed inline with the time.
  # If epics_only is true, only epic entries are printed.
  def self.print_day(daily_log, date_inline = false, epics_only = false)
    unless daily_log.date.respond_to?(:strftime)
      daily_log.date = Date.strptime(daily_log.date, '%Y-%m-%d')
    end

    date_string = daily_log.date.strftime('%a, %B %-d, %Y')
    unless date_inline
      puts "Work log for #{Rainbow(date_string).gold}"
    end

    daily_log.entries.each do |entry|
      next if epics_only && !entry.epic?

      print_entry(daily_log, entry, date_inline)
    end
  end

  def self.no_entries(start_date, end_date)
    if start_date == end_date
      date_string = start_date.strftime('%a, %B %-d, %Y')
      puts "No entries found for #{Rainbow(date_string).gold}."
    else
      start_date_string = start_date.strftime('%a, %B %-d, %Y')
      end_date_string = end_date.strftime('%a, %B %-d, %Y')
      puts "No entries found between #{Rainbow(start_date_string).gold} and #{Rainbow(end_date_string).gold}."
    end
  end

  private

  # Prints a single entry, formats the date and time.
  def print_entry(daily_log, entry, date_inline = false)
    unless entry.time.respond_to?(:strftime)
      entry.time = DateTime.strptime(entry.time, '%H:%M:%S')
    end

    if date_inline
      time_string = "#{daily_log.date.strftime('%a, %Y-%m-%d')} #{entry.time.strftime('%H:%M')}"
    else
      time_string = entry.time.strftime('%H:%M')
    end

    puts "#{Rainbow(time_string).gold} #{entry.message_string}"
  end

  module_function :print_entry
end
