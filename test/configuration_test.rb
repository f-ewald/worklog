# frozen_string_literal: true

require_relative 'test_helper'
require 'minitest/autorun'
require 'cli'
require 'configuration'
require 'tzinfo'
require 'erb'

class ConfigurationTest < Minitest::Test
  include Worklog

  def test_configuration_template
    refute_nil Configuration::CONFIGURATION_TEMPLATE
    assert_instance_of ERB, Configuration::CONFIGURATION_TEMPLATE

    result = Configuration::CONFIGURATION_TEMPLATE.result
    assert_instance_of String, result
  end

  def test_initialize
    config = Configuration.new
    assert_instance_of Configuration, config
    assert_equal File.join(Dir.home, '.worklog'), config.storage_path
    assert_equal :info, config.log_level
    assert_equal 3000, config.webserver_port
  end

  def test_initialize_project_nil
    project_config = Configuration::ProjectConfig.new(nil)
    assert_instance_of Configuration::ProjectConfig, project_config
    assert_nil project_config.show_last
  end

  def test_initialize_github_nil
    github_config = Configuration::GithubConfig.new(nil)
    assert_instance_of Configuration::GithubConfig, github_config
    assert_nil github_config.api_key
    assert_nil github_config.username
  end

  def test_initialize_with_block
    config = Configuration.new do |cfg|
      cfg.storage_path = File.join(Dir.tmpdir, '.worklog_test')
      cfg.log_level = :debug
      cfg.webserver_port = 4000
    end

    assert_equal :debug, config.log_level
    assert_equal 4000, config.webserver_port
    assert_equal File.join(Dir.tmpdir, '.worklog_test'), config.storage_path

    assert_instance_of Configuration::ProjectConfig, config.project
    assert_instance_of Configuration::GithubConfig, config.github
  end

  def test_initialize_timezone_default
    config = Configuration.new
    assert_equal TZInfo::Timezone.get('America/Los_Angeles'), config.timezone
  end

  def test_initialize_timezone
    config = Configuration.new do |cfg|
      cfg.timezone = 'America/New_York'
    end
    assert_equal TZInfo::Timezone.get('America/New_York'), config.timezone
  end

  def test_load_no_file
    # Test loading when config file does not exist
    Dir.mktmpdir do |dir|
      Dir.stub :home, dir do
        config = Configuration.load
        assert_instance_of Configuration, config
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

        project:
          show_last: 3

        github:
          api_key: 123abc
          username: sample-user
      YAML

      Dir.stub :home, dir do
        config = Configuration.load
        assert_instance_of Configuration, config
        assert_equal File.join(dir, '.worklog_test'), config.storage_path
        assert_equal :debug, config.log_level
        assert_equal 4000, config.webserver_port

        assert_instance_of Configuration::ProjectConfig, config.project
        assert_equal 3, config.project.show_last

        assert_instance_of Configuration::GithubConfig, config.github
        assert_equal '123abc', config.github.api_key
        assert_equal 'sample-user', config.github.username
      end
    end
  end

  def test_storage_path_exist
    Dir.mktmpdir do |dir|
      config = Configuration.new
      config.storage_path = dir
      assert config.storage_path_exist?

      # Create a non-existing path
      config.storage_path = File.join(dir, 'non_existing_path')
      refute config.storage_path_exist?
    end
  end

  def test_default_storage_path
    config = Configuration.new
    assert config.default_storage_path?

    # Change storage path to a non-default value
    config.storage_path = File.join(Dir.home, '.worklog_custom')
    refute config.default_storage_path?
  end

  def test_default_project
    config = Configuration.new
    assert_instance_of Configuration::ProjectConfig, config.project
    assert_nil config.project.show_last
  end

  def test_project_setter
    config = Configuration.new
    config.project.show_last = 99

    assert_equal 99, config.project.show_last
  end

  def test_default_github
    config = Configuration.new
    assert_instance_of Configuration::GithubConfig, config.github
    assert_nil config.github.api_key
    assert_nil config.github.username
  end

  def test_github_setter
    config = Configuration.new
    config.github.api_key = '123abc'
    config.github.username = 'sample-user'

    assert_equal '123abc', config.github.api_key
    assert_equal 'sample-user', config.github.username
  end

  def test_config_file_path
    assert_instance_of String, Configuration.config_file_path
    assert_equal File.join(Dir.home, '.worklog.yaml'), Configuration.config_file_path
  end
end
