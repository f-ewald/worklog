# frozen_string_literal: true

require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'
require_relative '../test_helper'
require 'commands/storage_command'

class StorageCommandTest < Minitest::Test
  include Worklog

  def setup
    @yaml_dir = Dir.mktmpdir('worklog_yaml_src')
    seed_yaml_source(@yaml_dir)
  end

  def teardown
    FileUtils.rm_rf(@yaml_dir)
    ::Worklog::DB.reset!
    ENV.delete('WORKLOG_DATABASE_URL')
  end

  def test_import_yaml_into_postgres_engine
    config_file = File.join(Dir.mktmpdir, '.worklog.yaml')
    File.write(config_file, <<~YAML)
      storage:
        engine: postgres
        postgres:
          url: "sqlite::memory:"
    YAML
    ENV['WORKLOG_DATABASE_URL'] = 'sqlite::memory:'

    ::Worklog::Configuration.stub :config_file_path, config_file do
      ::Worklog::Commands::StorageCommand.new.invoke(:import, [], path: @yaml_dir, format: 'yaml')

      config = ::Worklog::Configuration.load
      pg_storage = ::Worklog::Storage.build(config)

      assert_equal 1, pg_storage.all_days.size
      assert_equal Date.new(2024, 5, 1), pg_storage.all_days.first.date

      pg_people = ::Worklog::PeopleStorage.build(config)

      assert_equal %w[alex], pg_people.load_people.map(&:handle)

      pg_projects = ::Worklog::ProjectStorage.build(config)

      assert_equal ['P001'], pg_projects.load_projects.keys
    end
  end

  def test_export_postgres_to_yaml_dir
    config_file = File.join(Dir.mktmpdir, '.worklog.yaml')
    File.write(config_file, <<~YAML)
      storage:
        engine: postgres
        postgres:
          url: "sqlite::memory:"
    YAML
    ENV['WORKLOG_DATABASE_URL'] = 'sqlite::memory:'

    ::Worklog::Configuration.stub :config_file_path, config_file do
      # Seed the PG engine first by importing the YAML fixtures.
      ::Worklog::Commands::StorageCommand.new.invoke(:import, [], path: @yaml_dir, format: 'yaml')

      dest = Dir.mktmpdir('worklog_yaml_dest')
      begin
        ::Worklog::Commands::StorageCommand.new.invoke(:export, [], path: dest, format: 'yaml')

        assert_path_exists File.join(dest, '2024-05-01.yaml')
        assert_path_exists File.join(dest, 'people.yaml')
        assert_path_exists File.join(dest, 'projects.yaml')
      ensure
        FileUtils.rm_rf(dest)
      end
    end
  end

  private

  def seed_yaml_source(dir)
    File.write(File.join(dir, '2024-05-01.yaml'), <<~YAML)
      ---
      date: 2024-05-01
      entries:
        - time: 2024-05-01 09:00:00.000000000 Z
          tags:
            - tag1
          ticket: WL-1
          url: 'https://example.com/'
          epic: true
          message: hello
          project: P001
          source: manual
    YAML

    File.write(File.join(dir, 'people.yaml'), <<~YAML)
      ---
      - handle: alex
        name: Alex Test
        github_username: alextest
        email: alex@example.com
    YAML

    File.write(File.join(dir, 'projects.yaml'), <<~YAML)
      ---
      - key: P001
        name: Test Project
        description: A test project
        status: active
    YAML
  end
end
