# frozen_string_literal: true

require_relative 'test_helper'
require 'json'
require 'minitest/autorun'
require 'webmock/minitest'

require 'log_entry'
require 'summary'
require 'configuration'

class SummaryTest < Minitest::Test
  def setup
    stub_request(:post, 'http://localhost:11434/api/generate')
      .to_return(status: 200, body: { response: 'hello world' }.to_json, headers: { 'Content-Type' => 'application/json' })

    @configuration = configuration_helper
    @summary = Summary.new(@configuration)
  end

  def test_initialize
    summary = Summary.new(@configuration)
    assert_instance_of Summary, summary
  end

  def test_generate_summary
    entries = [
      Worklog::LogEntry.new(time: Time.new(2020, 1, 1, 10, 0, 0), ticket: 'ticket-123', url: 'https://example.com/', epic: true,
                   message: 'Created a feature to improve the performance of microservices by 200%'),
      Worklog::LogEntry.new(time: Time.new(2020, 1, 1, 11, 0, 0), ticket: 'ticket-123', url: 'https://example.com/', epic: true,
                   message: 'Introduced heartbeat monitoring to microservices to detect failures early')
    ]
    generated_summary = @summary.generate_summary(entries)

    refute_empty generated_summary
  end
end
