# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'github/push_event'

class PushEventTest < Minitest::Test
  include Worklog::Github

  def test_to_log_entry
    push_event = PushEvent.new
    log_entry = push_event.to_log_entry

    refute_nil log_entry
  end

  def test_push_event_to_s
    push_event = PushEvent.new

    assert_match(/\A#<Worklog::Github::PushEvent:0x[0-9a-f]+>\z/, push_event.to_s)
  end
end
