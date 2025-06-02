# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Needed to generate coverage reports.
# Otherwise the report will be generated too early, before the tests are run.
SimpleCov.external_at_exit = true

if ENV['CI']
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

SimpleCov.start do
  add_filter '/test/'
end
