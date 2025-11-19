# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'github/push_event'

class PushEventTest < Minitest::Test
  def test_push_event_to_s
    push_event = Worklog::Github::PushEvent.new

    assert_equal '#<struct Struct::PushEvent>', push_event.to_s
  end
end
