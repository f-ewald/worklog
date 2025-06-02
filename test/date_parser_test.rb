# frozen_string_literal: true

require 'date'
require 'minitest/autorun'
require_relative 'test_helper'
require_relative '../lib/date_parser'

class DateParserTest < Minitest::Test
  def test_parse_date_string
    assert_equal Date.new(2021, 1, 1), DateParser::parse_date_string('2021-01-01', true)
    assert_equal Date.new(2021, 1, 1), DateParser::parse_date_string('2021-01-01', false)
    assert_equal Date.new(2021, 10, 20), DateParser::parse_date_string('2021-10-20', true)
    assert_equal Date.new(2021, 10, 20), DateParser::parse_date_string('2021-10-20', false)
    assert_equal Date.new(2021, 1, 1), DateParser::parse_date_string('2021', true)
    assert_equal Date.new(2021, 12, 31), DateParser::parse_date_string('2021', false)
    assert_equal Date.new(2022, 1, 1), DateParser::parse_date_string('2022', true)
    assert_equal Date.new(2022, 12, 31), DateParser::parse_date_string('2022', false)
    assert_equal Date.new(2021, 2, 1), DateParser::parse_date_string('2021-02', true)
    assert_equal Date.new(2021, 2, 28), DateParser::parse_date_string('2021-02', false)
    assert_equal Date.new(2021, 2, 1), DateParser::parse_date_string('2021-2', true)
    assert_equal Date.new(2021, 2, 28), DateParser::parse_date_string('2021-2', false)
    assert_equal Date.new(2021, 10, 1), DateParser::parse_date_string('2021-10', true)
    assert_equal Date.new(2021, 10, 31), DateParser::parse_date_string('2021-10', false)
    assert_equal Date.new(2021, 1, 1), DateParser::parse_date_string('2021-Q1', true)
    assert_equal Date.new(2021, 3, 31), DateParser::parse_date_string('2021-Q1', false)
    assert_equal Date.new(2022, 4, 1), DateParser::parse_date_string('2022-Q2', true)
    assert_equal Date.new(2022, 6, 30), DateParser::parse_date_string('2022-Q2', false)
    assert_equal Date.new(2022, 4, 1), DateParser::parse_date_string('2022-q2', true)
    assert_equal Date.new(2022, 6, 30), DateParser::parse_date_string('2022-q2', false)
    assert_equal Date.new(Date.today.year, 1, 1), DateParser::parse_date_string('Q1', true)
    assert_equal Date.new(Date.today.year, 3, 31), DateParser::parse_date_string('Q1', false)
    assert_equal Date.new(Date.today.year, 1, 1), DateParser::parse_date_string('q1')
    assert_equal Date.new(Date.today.year, 4, 1), DateParser::parse_date_string('Q2')
    assert_equal Date.new(Date.today.year, 4, 1), DateParser::parse_date_string('q2')

    # Invalid cases
    assert_nil DateParser::parse_date_string('2021-13-01', true)
    assert_nil DateParser::parse_date_string('2021-13-01', false)
    assert_nil DateParser::parse_date_string('Q5', true)
    assert_nil DateParser::parse_date_string('Q5', false)
    assert_nil DateParser::parse_date_string('24-10-10', true)
    assert_nil DateParser::parse_date_string('24-10-10', false)
    assert_nil DateParser::parse_date_string('2021-10-10-10')
    assert_nil DateParser::parse_date_string(nil)
    assert_nil DateParser::parse_date_string('')
  end

  def test_parse_date_string!
    assert_equal Date.new(2021, 2, 1), DateParser::parse_date_string!('2021-02', true)
  end
end
