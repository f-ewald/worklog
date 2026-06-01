# frozen_string_literal: true

require 'date'
require 'rainbow'

# Renders a GitHub-style ASCII activity heatmap for worklog entries.
# Accepts an array of DailyLog objects and produces a 53-column × 7-row grid
# where each cell represents one day and darker (brighter) color means more activity.
#
# @example
#   graph = ActivityGraph.new(storage.all_days)
#   puts graph.render
class ActivityGraph
  DAYS_OF_WEEK = %w[Mon Tue Wed Thu Fri Sat Sun].freeze

  # Number of weeks to display (approx. one year).
  NUM_WEEKS = 53

  # Minimum column distance between consecutive month labels to prevent overlap.
  MIN_MONTH_GAP = 3

  def initialize(daily_logs)
    @daily_logs = Array(daily_logs)
  end

  # Render the activity graph as a printable multi-line string.
  # @return [String]
  def render
    counts    = count_by_date
    today     = Date.today
    start_date = week_start(today - ((NUM_WEEKS * 7) - 1))
    weeks      = build_weeks(start_date, today)
    max_count  = counts.values.max || 0

    lines = []
    lines << "  #{Rainbow('Activity — past year').bold}"
    lines << ''
    lines << month_header(weeks)

    DAYS_OF_WEEK.each_with_index do |day_name, day_idx|
      cells = weeks.map do |week|
        date = week[day_idx]
        next '  ' if date > today

        count = counts[date] || 0
        "#{colored_block(intensity_level(count, max_count))} "
      end
      lines << "#{day_name} #{cells.join}"
    end

    lines << ''
    lines << legend
    lines.join("\n")
  end

  private

  # Build a Hash mapping Date → entry count from the provided DailyLog objects.
  # @return [Hash{Date => Integer}]
  def count_by_date
    @daily_logs.each_with_object({}) do |daily_log, hash|
      date = daily_log.date.is_a?(Date) ? daily_log.date : Date.parse(daily_log.date.to_s)
      hash[date] = daily_log.entries.length
    end
  end

  # Return the Monday of the week that contains +date+.
  # @param date [Date]
  # @return [Date]
  def week_start(date)
    date - ((date.wday - 1) % 7)
  end

  # Build an array of weeks between +start_date+ and +end_date+.
  # Each week is an Array of 7 Date objects (index 0 = Monday … index 6 = Sunday).
  # +start_date+ must be a Monday.
  # @param start_date [Date]
  # @param end_date [Date]
  # @return [Array<Array<Date>>]
  def build_weeks(start_date, end_date)
    weeks = []
    current = start_date
    while current <= end_date
      weeks << (0..6).map { |i| current + i }
      current += 7
    end
    weeks
  end

  # Map an entry count to an intensity level 0–4.
  # Uses relative scaling so the full colour range adapts to the user's habits.
  # Any day with at least one entry is guaranteed level ≥ 1.
  # @param count [Integer]
  # @param max_count [Integer]
  # @return [Integer] 0–4
  def intensity_level(count, max_count)
    return 0 if count.zero? || max_count.zero?

    ratio = count.to_f / max_count
    return 1 if ratio <= 0.25
    return 2 if ratio <= 0.50
    return 3 if ratio <= 0.75

    4
  end

  # Return a Rainbow-coloured Unicode block for the given intensity level.
  # Brighter green = more activity (optimised for dark-background terminals).
  # @param level [Integer] 0–4
  # @return [String]
  def colored_block(level)
    case level
    when 0 then Rainbow('░').color(0x4a, 0x4a, 0x4a)    # dark grey  – no activity
    when 1 then Rainbow('█').color(0x0e, 0x44, 0x29)    # very dark green
    when 2 then Rainbow('█').color(0x30, 0xa1, 0x4e)    # medium green
    when 3 then Rainbow('█').color(0x40, 0xc4, 0x63)    # bright green
    else        Rainbow('█').color(0x9b, 0xe9, 0xa8)    # very bright green – peak activity
    end
  end

  # Build the month-label header row aligned with the week columns.
  # Month names are placed at the column where the month first appears.
  # A label is skipped when fewer than MIN_MONTH_GAP columns separate it from
  # the previous one, preventing overlapping abbreviations at the graph edges.
  # @param weeks [Array<Array<Date>>]
  # @return [String]
  def month_header(weeks)
    # 4-char prefix to align with "Mon " row labels; 2 chars per week column.
    buffer         = ' ' * (4 + (weeks.length * 2))
    prev_month     = nil
    last_label_col = -ActivityGraph::MIN_MONTH_GAP # allow first label at col 0

    weeks.each_with_index do |week, col_idx|
      month = week.first.month
      next if month == prev_month
      next if col_idx - last_label_col < MIN_MONTH_GAP

      name = week.first.strftime('%b')
      pos  = 4 + (col_idx * 2)
      buffer[pos, name.length] = name
      prev_month     = month
      last_label_col = col_idx
    end

    buffer
  end

  # Return the legend row.
  # @return [String]
  def legend
    blocks = (0..4).map { |level| colored_block(level) }
    "     Less #{blocks.join(' ')} More"
  end
end
