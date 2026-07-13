# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'simplecov'
require 'simplecov-cobertura'

require 'configuration'
require 'storage'

# Needed to generate coverage reports.
# Otherwise the report will be generated too early, before the tests are run.
SimpleCov.external_at_exit = true

if ENV['CI']
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

SimpleCov.start do
  add_filter '/test/'
  minimum_coverage 80
end


# Provide a sample YAML-backed configuration for testing purposes.
def configuration_helper
  tmp_dir = File.join(Dir.tmpdir, 'worklog_test')
  Dir.mkdir(tmp_dir) unless Dir.exist?(tmp_dir)

  Worklog::Configuration.new do |config|
    config.storage_path = File.join(Dir.tmpdir, 'worklog_test')
    config.log_level = :debug

    config.github = Worklog::Configuration::GithubConfig.new
    config.github.api_key = 'test-api-key'
  end
end

def teardown_configuration
  tmp_dir = File.join(Dir.tmpdir, 'worklog_test')
  FileUtils.rm_rf(tmp_dir) if Dir.exist?(tmp_dir)
end

def storage_helper
  Worklog::Storage.build(configuration_helper)
end

# Build a Postgres-engine configuration backed by an in-memory SQLite
# DB. The migrations are SQLite-compatible (see `db/migrations/*.rb`)
# so tests get a fresh, fully-migrated schema per call.
def postgres_configuration_helper
  require 'db'
  ENV['WORKLOG_DATABASE_URL'] = 'sqlite::memory:'
  ::Worklog::DB.reset!
  ::Worklog::Configuration.new do |config|
    config.storage = ::Worklog::Configuration::StorageConfig.new
    config.storage.engine = :postgres
    config.storage.postgres_url = 'sqlite::memory:'
    config.log_level = :debug
  end
end

def teardown_postgres_configuration
  require 'db'
  ::Worklog::DB.reset!
  ENV.delete('WORKLOG_DATABASE_URL')
end
