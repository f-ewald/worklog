require 'simplecov'

# Needed to generate coverage reports.
# Otherwise the report will be generated too early, before the tests are run.
SimpleCov.external_at_exit = true

SimpleCov.start do
  add_filter '/test/'
end
