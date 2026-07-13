# frozen_string_literal: true

require 'storage/base'
require 'storage/yaml'
require 'storage/postgres'

module Worklog
  # Daily-log storage. The {Storage} namespace contains:
  #
  # * {Storage::Base}     — abstract API contract
  # * {Storage::Yaml}     — one YAML file per day under `config.storage_path`
  # * {Storage::Postgres} — rows in a PostgreSQL database
  #
  # Callers obtain a concrete backend with {Storage.build}, which reads
  # `config.storage_engine` and returns the matching subclass.
  module Storage
    # Construct the storage backend selected by the configuration.
    # @param config [Worklog::Configuration]
    # @return [Storage::Base]
    def self.build(config)
      case config.storage_engine
      when :postgres then Postgres.new(config)
      else Yaml.new(config)
      end
    end
  end
end
