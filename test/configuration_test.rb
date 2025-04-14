# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../worklog/cli'
require_relative '../worklog/configuration'

class ConfigurationTest < Minitest::Test
  def test_load_configuration
    config = Configuration.new do |cfg|
      cfg.storage_path = File.join(Dir.home, '.worklog2')
      cfg.log_level = :debug
      cfg.webserver_port = 4000
    end

    assert_equal File.join(Dir.home, '.worklog2'), config.storage_path
    assert_equal :debug, config.log_level
    assert_equal 4000, config.webserver_port

    # Test default values
    default_config = Configuration.new
    assert_equal File.join(Dir.home, '.worklog'), default_config.storage_path
    assert_equal :info, default_config.log_level
    assert_equal 3000, default_config.webserver_port

    # Test loading configuration from a file
    config = load_configuration
    refute_nil config
  end

end