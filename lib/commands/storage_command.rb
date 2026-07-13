# frozen_string_literal: true

require 'fileutils'
require 'thor'
require 'configuration'
require 'people_storage'
require 'project_storage'
require 'storage'
require 'worklogger'

module Worklog
  module Commands
    # Thor subcommand for moving worklog data between storage engines.
    #
    # The currently-configured engine (`storage.engine` in
    # `~/.worklog.yaml`) is the source for `export` and the destination
    # for `import`. To migrate YAML → Postgres, leave the engine on
    # `yaml`, run `wl storage export --path=DIR`, switch the engine to
    # `postgres`, then `wl storage import --path=DIR`.
    class StorageCommand < Thor
      def self.exit_on_failure? = true

      desc 'export', 'Export worklog data from the current engine to a directory of YAML files'
      option :path, type: :string, required: true,
                    desc: 'Destination directory. Will be created if it does not exist.'
      option :format, type: :string, default: 'yaml', enum: %w[yaml],
                      desc: 'Output format. Currently only yaml is supported.'
      def export
        config = ::Worklog::Configuration.load
        dest = File.expand_path(options[:path])
        FileUtils.mkdir_p(dest)

        export_daily_logs(config, dest)
        export_people(config, dest)
        export_projects(config, dest)

        ::WorkLogger.info "Exported #{config.storage_engine} data to #{dest}"
      end

      desc 'import', 'Import worklog data from a directory of YAML files into the current engine'
      option :path, type: :string, required: true,
                    desc: 'Source directory containing YAML files to import.'
      option :format, type: :string, default: 'yaml', enum: %w[yaml],
                      desc: 'Input format. Currently only yaml is supported.'
      def import
        config = ::Worklog::Configuration.load
        src = File.expand_path(options[:path])
        raise Thor::Error, "Source directory #{src} does not exist" unless Dir.exist?(src)

        # Build a YAML-rooted config so we can read from `src` regardless
        # of the currently-active engine.
        yaml_source_config = build_yaml_config_for(src, config)

        import_daily_logs(yaml_source_config, config)
        import_people(yaml_source_config, config)
        import_projects(yaml_source_config, config)

        ::WorkLogger.info "Imported YAML data from #{src} into the #{config.storage_engine} engine"
      end

      private

      # @param src [String]
      # @param base_config [Worklog::Configuration]
      # @return [Worklog::Configuration]
      def build_yaml_config_for(src, base_config)
        ::Worklog::Configuration.new do |cfg|
          cfg.storage = ::Worklog::Configuration::StorageConfig.new
          cfg.storage.engine = :yaml
          cfg.storage.yaml_path = src
          cfg.log_level = base_config.log_level
          cfg.timezone = base_config.timezone
        end
      end

      def export_daily_logs(config, dest)
        src_storage = ::Worklog::Storage.build(config)
        yaml_dest_config = build_yaml_config_for(dest, config)
        dest_storage = ::Worklog::Storage::Yaml.new(yaml_dest_config)
        src_storage.all_days.each { |daily_log| dest_storage.save_log(daily_log) }
      end

      def export_people(config, dest)
        src_people = ::Worklog::PeopleStorage.build(config)
        yaml_dest_config = build_yaml_config_for(dest, config)
        dest_people = ::Worklog::PeopleStorage::Yaml.new(yaml_dest_config)
        dest_people.write_people!(src_people.load_people)
      end

      def export_projects(config, dest)
        src_projects = ::Worklog::ProjectStorage.build(config)
        yaml_dest_config = build_yaml_config_for(dest, config)
        dest_projects = ::Worklog::ProjectStorage::Yaml.new(yaml_dest_config)
        dest_projects.write_projects!(src_projects.load_projects.values)
      end

      def import_daily_logs(yaml_source_config, config)
        src_storage = ::Worklog::Storage::Yaml.new(yaml_source_config)
        dest_storage = ::Worklog::Storage.build(config)
        src_storage.all_days.each { |daily_log| dest_storage.save_log(daily_log) }
      end

      def import_people(yaml_source_config, config)
        src_people = ::Worklog::PeopleStorage::Yaml.new(yaml_source_config)
        dest_people = ::Worklog::PeopleStorage.build(config)
        dest_people.write_people!(src_people.load_people)
      end

      def import_projects(yaml_source_config, config)
        src_projects = ::Worklog::ProjectStorage::Yaml.new(yaml_source_config)
        dest_projects = ::Worklog::ProjectStorage.build(config)
        dest_projects.write_projects!(src_projects.load_projects.values)
      end
    end
  end
end
