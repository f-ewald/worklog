# frozen_string_literal: true

require 'project_storage/base'
require 'project_storage/yaml'
require 'project_storage/postgres'

module Worklog
  # Project storage. See {Storage} and {PeopleStorage} for the
  # analogous pattern.
  module ProjectStorage
    # Construct the project storage backend selected by the
    # configuration.
    # @param config [Worklog::Configuration]
    # @return [ProjectStorage::Base]
    def self.build(config)
      case config.storage_engine
      when :postgres then Postgres.new(config)
      else Yaml.new(config)
      end
    end
  end
end
