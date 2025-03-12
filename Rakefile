# frozen_string_literal: true

require 'minitest/test_task'
require 'rubocop/rake_task'
require 'yard'

RuboCop::RakeTask.new

Minitest::TestTask.create # named test, sensible defaults

task default: :test

task :package do
  puts 'Packaging the application for distribution'
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['worklog/**/*.rb']
  t.options = ['--title Worklog']
end
