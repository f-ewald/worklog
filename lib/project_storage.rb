# frozen_string_literal: true

require 'project_storage/base'
require 'project_storage/yaml'
require 'project_storage/postgres'
require 'storage_factory'

module Worklog
  # Project storage. See {Storage} and {PeopleStorage} for the
  # analogous pattern.
  module ProjectStorage
    # Construct the project storage backend selected by the
    # configuration.
    # @param config [Worklog::Configuration]
    # @return [ProjectStorage::Base]
    def self.build(config)
      StorageFactory.build(config, yaml_class: Yaml, postgres_class: Postgres)
    end
  end
end
