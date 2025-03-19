# frozen_string_literal: true

require_relative 'worklog/version'

Gem::Specification.new do |spec|
  spec.name          = 'fewald-worklog'
  spec.version       = current_version
  spec.license       = 'MIT'
  spec.authors       = ['Friedrich Ewald']
  spec.homepage      = 'https://github.com/f-ewald/worklog'
  spec.summary       = 'Command line tool for tracking achievments, tasks and interactions.'
  spec.description   = <<~DESC
    Command line tool for tracking achievments, tasks and interactions.

    You can add work items, view them and run a webserver to share them with other people,
    for example via screen sharing.

    This tool is designed to run in a terminal completely local without sharing any data with
    any other service. No telemetry, no tracking, no data sharing of any kind.
  DESC
  spec.metadata = {
    'documentation_uri' => 'https://f-ewald.github.io/worklog',
    'rubygems_mfa_required' => 'true'
  }
  spec.required_ruby_version = '>= 3.4.0'
  spec.bindir = 'bin'
  spec.post_install_message = <<~MESSAGE
    Thanks for installing worklog! Now you can use it by running wl from your terminal.'
  MESSAGE
  spec.files = Dir.glob('worklog/**/*.{erb,rb}') + ['.version']
  spec.executables = ['wl']

  spec.add_dependency 'httparty', '~> 0.22.0'
  spec.add_dependency 'logger', '~> 1.6'
  spec.add_dependency 'rack', '~> 3.1'
  spec.add_dependency 'rackup', '~> 2.2'
  spec.add_dependency 'rainbow', '~> 3.1'
  spec.add_dependency 'thor', '~> 1.3'
end
