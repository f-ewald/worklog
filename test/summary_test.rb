# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require 'webmock/minitest'

require_relative '../worklog/log_entry'
require_relative '../worklog/summary'

class SummaryTest < Minitest::Test
  def setup
    stub_request(:post, "http://localhost:11434/api/generate").
    to_return(status: 200, body: {response: "hello world"}.to_json, headers: {'Content-Type' => 'application/json'})
  end

  def test_generate_summary
    entries = [
      LogEntry.new(Time.new(2020, 1, 1, 10, 0, 0), nil, 'ticket-123', true, 'Created a feature to improve the performance of microservices by 200%'),
      LogEntry.new(Time.new(2020, 1, 1, 11, 0, 0), nil, 'ticket-123', true, 'Introduced heartbeat monitoring to microservices to detect failures early'),
    ]
    generated_summary = Summary.generate_summary(entries)
    refute_empty generated_summary
  end
end
