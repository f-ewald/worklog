# frozen_string_literal: true

source 'https://rubygems.org'

# Globally required Gems
gem 'dotenv-vault', '~> 0.10.1'
gem 'faraday', '~> 2.14'
gem 'httparty', '~> 0.22.0'
gem 'langchainrb', '~> 0.19.5'
gem 'logger', '~> 1.6'
gem 'rack', '~> 3.1'
gem 'rackup', '~> 2.2'
gem 'rainbow', '~> 3.1'
gem 'ruby-openai', '~> 8.3'
gem 'thor', '~> 1.3'
gem 'tzinfo', '~> 2.0'

# Gems required for development
group :development do
  gem 'puma', '~> 6.6'
  gem 'rake', '~> 13.2'
  gem 'rdoc', '~> 6.12'
  gem 'reline', '~> 0.6.0'
  gem 'rubocop-rake', '~> 0.6.0'
  gem 'webmock', '~> 3.24'
  gem 'yard', '~> 0.9.37'
end

# Gems required for testing
group :test do
  gem 'guard', '~> 2.19'
  gem 'guard-bundler', '~> 3.0'
  gem 'guard-minitest', '~> 2.4'
  gem 'guard-rubocop', '~> 1.5'
  gem 'minitest', '~> 5.25'
  gem 'rubocop', '~> 1.81'
  gem 'rubocop-minitest', '~> 0.36.0'
  gem 'simplecov', '~> 0.22.0'
  gem 'simplecov-cobertura', '~> 3.1'
  gem 'terminal-notifier-guard', '~> 1.7'
end

# Load version of Ruby from .tool-versions file (ASDF)
ruby file: '.tool-versions'
