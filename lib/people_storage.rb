# frozen_string_literal: true

require 'people_storage/base'
require 'people_storage/yaml'
require 'people_storage/postgres'

module Worklog
  # People storage. See {Storage} for the analogous pattern with the
  # daily log backends.
  module PeopleStorage
    # Construct the people storage backend selected by the
    # configuration.
    # @param config [Worklog::Configuration]
    # @return [PeopleStorage::Base]
    def self.build(config)
      case config.storage_engine
      when :postgres then Postgres.new(config)
      else Yaml.new(config)
      end
    end
  end
end
