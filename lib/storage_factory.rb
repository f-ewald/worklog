# frozen_string_literal: true

module Worklog
  # Shared factory helper for selecting a storage backend based on the
  # configured engine. All storage namespaces (Storage, PeopleStorage,
  # ProjectStorage) delegate to this so backend selection is defined
  # in exactly one place.
  #
  # @example Adding a new backend
  #   StorageFactory.build(config, yaml_class: Yaml, postgres_class: Postgres,
  #                        redis_class: Redis)
  module StorageFactory
    # Instantiate the backend class that matches +config.storage_engine+.
    #
    # @param config [Worklog::Configuration]
    # @param yaml_class [Class] the YAML backend class
    # @param postgres_class [Class] the Postgres backend class
    # @return [Object] a new instance of the selected backend class
    def self.build(config, yaml_class:, postgres_class:)
      case config.storage_engine
      when :postgres then postgres_class.new(config)
      else yaml_class.new(config)
      end
    end
  end
end
