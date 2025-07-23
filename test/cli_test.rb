# frozen_string_literal: true

require 'minitest/autorun'

require_relative 'test_helper'
require 'cli'
require 'configuration'

class CliTest < Minitest::Test
  def setup
    @cli = WorklogCLI.new
    @cli.config = configuration_helper
    @cli.storage = storage_helper
  end

  def test_configure_cli
    config = Configuration.new do |cfg|
      cfg.storage_path = 'test/storage'
      cfg.log_level = :debug
      cfg.webserver_port = 8080
    end
    cli = WorklogCLI.new
    cli.config = config
    refute_nil cli.config
    assert_equal 'test/storage', cli.config.storage_path
    assert_equal :debug, cli.config.log_level
    assert_equal 8080, cli.config.webserver_port
  end

  def test_exit_on_failure
    assert WorklogCLI.exit_on_failure?
  end

  def test_format_left
    assert_equal '              test', @cli.format_left('test')
    assert_equal '                  ', @cli.format_left('')
    assert_equal '123456789012345678', @cli.format_left('123456789012345678')
    assert_equal '1234567890123456789', @cli.format_left('1234567890123456789')
  end

  def test_show
    @cli.invoke(:show, [], verbose: true)
  end

  def test_show_days
    # out, _err = capture_io { @cli.invoke(:show, ['--days 10'], verbose: true) }
    # refute_match 'Number of days cannot be negative', out

    # out, _err = capture_io { @cli.invoke(:show, ['--days', '-1'], verbose: true) }
    # assert_match 'Number of days cannot be negative', out
  end

  def test_stats
    @cli.invoke(:stats, [], verbose: true)
  end

  def test_tags
    @cli.invoke(:tags, [], verbose: true)
  end

  def test_people
    @cli.invoke(:people, [], verbose: true)
  end
end
