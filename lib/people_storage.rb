# frozen_string_literal: true

require 'people_storage/base'
require 'people_storage/yaml'
require 'people_storage/postgres'
require 'storage_factory'

module Worklog
  # People storage. See {Storage} for the analogous pattern with the
  # daily log backends.
  module PeopleStorage
    # Construct the people storage backend selected by the
    # configuration.
    # @param config [Worklog::Configuration]
    # @return [PeopleStorage::Base]
    def self.build(config)
      StorageFactory.build(config, yaml_class: Yaml, postgres_class: Postgres)
    end
  end
end
