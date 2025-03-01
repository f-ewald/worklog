# frozen_string_literal: true

require 'minitest/autorun'

require_relative 'test_helper'
require_relative '../worklog/cli'

class CliTest < Minitest::Test
  def setup
    @cli = WorklogCLI.new
  end

  def test_show
    @cli.invoke(:show, [], verbose: true)
  end

  def test_cli_add
    skip 'not yet implemented'

  end
end