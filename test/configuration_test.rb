# frozen_string_literal: true

require_relative 'test_helper'
require 'minitest/autorun'
require 'cli'
require 'configuration'

class ConfigurationTest < Minitest::Test
  def test_initialize
    config = Worklog::Configuration.new
    assert_instance_of Worklog::Configuration, config
    assert_equal File.join(Dir.home, '.worklog'), config.storage_path
    assert_equal :info, config.log_level
    assert_equal 3000, config.webserver_port
  end

  def test_initialize_with_block
    config = Worklog::Configuration.new do |cfg|
      cfg.storage_path = File.join(Dir.tmpdir, '.worklog_test')
      cfg.log_level = :debug
      cfg.webserver_port = 4000
    end

    assert_equal :debug, config.log_level
  end

  def test_load_no_file
    # Test loading when config file does not exist
    Dir.mktmpdir do |dir|
      Dir.stub :home, dir do
        config = Worklog::Configuration.load
        assert_instance_of Worklog::Configuration, config
        assert_equal config.log_level, :info
        assert_equal config.storage_path, File.join(dir, '.worklog')
        assert_equal config.webserver_port, 3000
      end
    end
  end

  def test_load_with_file
    # Create a temporary YAML file for testing
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, '.worklog.yaml')
      File.write(file_path, <<~YAML)
        storage_path: #{File.join(dir, '.worklog_test')}
        log_level: debug
        webserver_port: 4000
      YAML

      Dir.stub :home, dir do
        config = Worklog::Configuration.load
        assert_instance_of Worklog::Configuration, config
        assert_equal File.join(dir, '.worklog_test'), config.storage_path
        assert_equal :debug, config.log_level
        assert_equal 4000, config.webserver_port
      end
    end
  end

  def test_storage_path_exist
    Dir.mktmpdir do |dir|
      config = Worklog::Configuration.new
      config.storage_path = dir
      assert config.storage_path_exist?

      # Create a non-existing path
      config.storage_path = File.join(dir, 'non_existing_path')
      refute config.storage_path_exist?
    end
  end

  def test_default_storage_path
    config = Worklog::Configuration.new
    assert config.default_storage_path?

    # Change storage path to a non-default value
    config.storage_path = File.join(Dir.home, '.worklog_custom')
    refute config.default_storage_path?
  end
end
