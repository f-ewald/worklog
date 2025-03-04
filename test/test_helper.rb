# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'

# Needed to generate coverage reports.
# Otherwise the report will be generated too early, before the tests are run.
SimpleCov.external_at_exit = true
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

SimpleCov.start do
  add_filter '/test/'
end
