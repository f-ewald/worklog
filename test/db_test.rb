# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'
require 'db'

class DBTest < Minitest::Test
  include Worklog

  def teardown
    ::Worklog::DB.reset!
    ENV.delete('WORKLOG_DATABASE_URL')
  end

  def test_connect_uses_env_url_when_set
    ENV['WORKLOG_DATABASE_URL'] = 'sqlite::memory:'
    config = ::Worklog::Configuration.new do |cfg|
      cfg.storage = ::Worklog::Configuration::StorageConfig.new
      cfg.storage.engine = :postgres
      cfg.storage.postgres_url = 'postgres://unused'
    end

    db = ::Worklog::DB.connection(config)
    refute_nil db
    assert_equal :sqlite, db.database_type
  end

  def test_connect_memoizes
    ENV['WORKLOG_DATABASE_URL'] = 'sqlite::memory:'
    config = ::Worklog::Configuration.new do |cfg|
      cfg.storage = ::Worklog::Configuration::StorageConfig.new
      cfg.storage.engine = :postgres
    end

    a = ::Worklog::DB.connection(config)
    b = ::Worklog::DB.connection(config)
    assert_same a, b
  end

  def test_reset_returns_fresh_connection
    ENV['WORKLOG_DATABASE_URL'] = 'sqlite::memory:'
    config = ::Worklog::Configuration.new do |cfg|
      cfg.storage = ::Worklog::Configuration::StorageConfig.new
      cfg.storage.engine = :postgres
    end

    a = ::Worklog::DB.connection(config)
    ::Worklog::DB.reset!
    b = ::Worklog::DB.connection(config)
    refute_same a, b
  end

  def test_missing_url_raises_configuration_error
    ENV.delete('WORKLOG_DATABASE_URL')
    config = ::Worklog::Configuration.new do |cfg|
      cfg.storage = ::Worklog::Configuration::StorageConfig.new
      cfg.storage.engine = :postgres
      cfg.storage.postgres_url = nil
    end

    assert_raises(::Worklog::DB::ConfigurationError) do
      ::Worklog::DB.connect!(config)
    end
  end

  def test_migrations_apply_expected_tables
    ENV['WORKLOG_DATABASE_URL'] = 'sqlite::memory:'
    config = ::Worklog::Configuration.new do |cfg|
      cfg.storage = ::Worklog::Configuration::StorageConfig.new
      cfg.storage.engine = :postgres
    end

    db = ::Worklog::DB.connection(config)
    assert db.table_exists?(:daily_logs)
    assert db.table_exists?(:log_entries)
    assert db.table_exists?(:people)
    assert db.table_exists?(:projects)
  end
end
