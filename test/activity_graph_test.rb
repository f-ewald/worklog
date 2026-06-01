# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'

require 'activity_graph'
require 'daily_log'
require 'log_entry'

class ActivityGraphTest < Minitest::Test
  def setup
    @today = Date.today
  end

  # Helper: build a minimal DailyLog with n entries on the given date.
  def make_log(date, entry_count = 1)
    entries = entry_count.times.map do |i|
      Worklog::LogEntry.new(
        message: "Entry #{i}",
        time: Time.new(date.year, date.month, date.day, 9 + i, 0, 0)
      )
    end
    Worklog::DailyLog.new(date: date, entries: entries)
  end

  def test_render_returns_non_empty_string
    graph = ActivityGraph.new([])
    result = graph.render
    refute_nil result
    refute_empty result
  end

  def test_render_with_empty_logs_does_not_raise
    assert_silent { ActivityGraph.new([]).render }
  end

  def test_render_includes_all_day_labels
    result = ActivityGraph.new([]).render
    %w[Mon Tue Wed Thu Fri Sat Sun].each do |day|
      assert_includes result, day, "Expected day label '#{day}' to appear in the graph"
    end
  end

  def test_render_includes_legend
    result = ActivityGraph.new([]).render
    assert_includes result, 'Less'
    assert_includes result, 'More'
  end

  def test_render_includes_month_labels
    result = ActivityGraph.new([]).render
    # At least two different months should appear in a 53-week window
    months = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    found = months.count { |m| result.include?(m) }
    assert found >= 2, "Expected at least 2 month labels, found #{found}"
  end

  def test_render_with_single_entry_does_not_raise
    log = make_log(@today)
    assert_silent { ActivityGraph.new([log]).render }
  end

  def test_render_with_multiple_days_does_not_raise
    logs = [
      make_log(@today, 3),
      make_log(@today - 1, 1),
      make_log(@today - 8, 5)
    ]
    assert_silent { ActivityGraph.new(logs).render }
  end

  # --- intensity_level ---

  def test_intensity_level_zero_for_no_entries
    graph = ActivityGraph.new([])
    assert_equal 0, graph.send(:intensity_level, 0, 10)
  end

  def test_intensity_level_zero_when_max_is_zero
    graph = ActivityGraph.new([])
    assert_equal 0, graph.send(:intensity_level, 0, 0)
  end

  def test_intensity_level_one_at_lower_boundary
    graph = ActivityGraph.new([])
    # count == 1, max == 4 → ratio = 0.25 → level 1
    assert_equal 1, graph.send(:intensity_level, 1, 4)
  end

  def test_intensity_level_two_at_mid_range
    graph = ActivityGraph.new([])
    # count == 2, max == 4 → ratio = 0.5 → level 2
    assert_equal 2, graph.send(:intensity_level, 2, 4)
  end

  def test_intensity_level_three_at_upper_mid
    graph = ActivityGraph.new([])
    # count == 3, max == 4 → ratio = 0.75 → level 3
    assert_equal 3, graph.send(:intensity_level, 3, 4)
  end

  def test_intensity_level_four_at_maximum
    graph = ActivityGraph.new([])
    # count == max → ratio = 1.0 → level 4
    assert_equal 4, graph.send(:intensity_level, 10, 10)
  end

  # --- count_by_date ---

  def test_count_by_date_returns_correct_counts
    logs = [make_log(@today, 3), make_log(@today - 1, 7)]
    graph = ActivityGraph.new(logs)
    counts = graph.send(:count_by_date)
    assert_equal 3, counts[@today]
    assert_equal 7, counts[@today - 1]
  end

  def test_count_by_date_empty_for_no_logs
    graph = ActivityGraph.new([])
    assert_empty graph.send(:count_by_date)
  end

  # --- week_start ---

  def test_week_start_returns_monday
    monday = Date.new(2024, 1, 1)  # Monday
    graph  = ActivityGraph.new([])
    assert_equal monday, graph.send(:week_start, monday)
  end

  def test_week_start_for_wednesday_returns_preceding_monday
    wednesday = Date.new(2024, 1, 3)  # Wednesday
    monday    = Date.new(2024, 1, 1)
    graph     = ActivityGraph.new([])
    assert_equal monday, graph.send(:week_start, wednesday)
  end

  def test_week_start_for_sunday_returns_preceding_monday
    sunday = Date.new(2024, 1, 7)  # Sunday
    monday = Date.new(2024, 1, 1)
    graph  = ActivityGraph.new([])
    assert_equal monday, graph.send(:week_start, sunday)
  end

  # --- build_weeks ---

  def test_build_weeks_returns_correct_number_of_weeks
    graph      = ActivityGraph.new([])
    start_date = Date.new(2024, 1, 1)   # Monday
    end_date   = Date.new(2024, 1, 14)  # covers 2 complete weeks
    weeks      = graph.send(:build_weeks, start_date, end_date)
    assert_equal 2, weeks.length
  end

  def test_build_weeks_first_day_is_start_date
    graph      = ActivityGraph.new([])
    start_date = Date.new(2024, 1, 1)
    end_date   = Date.new(2024, 1, 7)
    weeks      = graph.send(:build_weeks, start_date, end_date)
    assert_equal start_date, weeks.first.first
  end

  def test_build_weeks_each_week_has_seven_days
    graph  = ActivityGraph.new([])
    start  = Date.new(2024, 1, 1)
    weeks  = graph.send(:build_weeks, start, start + 20)
    weeks.each { |w| assert_equal 7, w.length }
  end
end
