# frozen_string_literal: true

# Use terminal notifier on Mac OS
notification :terminal_notifier if `uname` =~ /Darwin/

# Disable interaction from command line with Guard
interactor :off

guard :minitest do
  require 'guard/minitest'

  watch(%r{^test/(.*)\.rb$})
  watch(%{^worklog/(.*).rb$}) { |m| "test/#{m[1]}_test.rb" }

  # Execute all tests upon change of the test_helper.rb file
  watch(%r{^test/test_helper\.rb$}) { 'test' }
end

guard :bundler do
  require 'guard/bundler'
  require 'guard/bundler/verify'
  helper = Guard::Bundler::Verify.new

  files = ['Gemfile']
  files += Dir['*.gemspec'] if files.any? { |f| helper.uses_gemspec?(f) }

  # Assume files are symlinked from somewhere
  files.each { |file| watch(helper.real_path(file)) }
end
