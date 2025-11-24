# frozen_string_literal: true

require_relative '../test_helper'
require 'minitest/autorun'
require 'github/pull_request_details'

class PullRequestDetailsTest < Minitest::Test
  include Worklog::Github

  def test_merged_method
    pr_open = PullRequestDetails.new(state: 'open', merged: false)
    pr_closed_not_merged = PullRequestDetails.new(state: 'closed', merged: false)
    pr_closed_merged = PullRequestDetails.new(state: 'closed', merged: true)

    refute_predicate(pr_open, :merged?)
    refute_predicate(pr_closed_not_merged, :merged?)
    assert_predicate(pr_closed_merged, :merged?)
  end
end
