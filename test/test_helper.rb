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
end


# Provide a sample configuration for testing purposes.
def configuration_helper
  tmp_dir = File.join(Dir.tmpdir, 'worklog_test')
  Dir.mkdir(tmp_dir) unless Dir.exist?(tmp_dir)

  Worklog::Configuration.new do |config|
    config.storage_path = File.join(Dir.tmpdir, 'worklog_test')
    config.log_level = :debug
  end
end

def teardown_configuration
  tmp_dir = File.join(Dir.tmpdir, 'worklog_test')
  FileUtils.rm_rf(tmp_dir) if Dir.exist?(tmp_dir)
end

def storage_helper
  Worklog::Storage.new(configuration_helper)
end
