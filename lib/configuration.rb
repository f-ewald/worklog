# frozen_string_literal: true

require 'erb'
require 'tzinfo'
require 'worklogger'
require 'yaml'

module Worklog
  # Configuration class for the application.
  # @!attribute [rw] storage_path
  #   @return [String] The path where the application stores its data
  #     when the YAML engine is in use. For PostgreSQL, this value is
  #     ignored at runtime.
  # @!attribute [rw] storage
  #   @return [Configuration::StorageConfig] Storage engine selection and
  #     engine-specific settings (YAML path, PostgreSQL URL/pool, ...).
  # @!attribute [rw] log_level
  #   @return [Symbol] The logging level for the application.
  #   Possible values: :debug, :info, :warn, :error, :fatal
  # @!attribute [rw] webserver_port
  #   @return [Integer] The port on which the web server runs.
  #   Default is 3000.
  # @!attribute [rw] project
  #   @return [Configuration::ProjectConfig] Project related configuration.
  # @!attribute [rw] github
  #   @return [Configuration::GithubConfig] Github related configuration.
  #
  # @example Example ~/.worklog.yaml (new shape)
  #   storage:
  #     engine: yaml         # or 'postgres'
  #     yaml:
  #       path: /Users/username/.worklog
  #     postgres:
  #       url: postgres://user:pass@localhost:5432/worklog
  #       pool: 5
  #   log_level: debug
  #   timezone: 'America/Los_Angeles'
  #   webserver_port: 4000
  #
  #   project:
  #     show_last: 3
  #
  #   github:
  #     api_key: 123abc
  #     username: sample-user
  class Configuration
    attr_accessor :log_level, :timezone, :webserver_port, :project, :github, :storage

    # Configuration for the storage engine.
    # @!attribute [rw] engine
    #   @return [Symbol] :yaml or :postgres
    # @!attribute [rw] yaml_path
    #   @return [String] Filesystem path for the YAML engine (defaults to ~/.worklog).
    # @!attribute [rw] postgres_url
    #   @return [String, nil] Connection URL for the Postgres engine.
    # @!attribute [rw] postgres_pool
    #   @return [Integer] Max connection pool size for the Postgres engine.
    class StorageConfig
      DEFAULT_POSTGRES_POOL = 5
      VALID_ENGINES = %i[yaml postgres].freeze

      attr_accessor :engine, :yaml_path, :postgres_url, :postgres_pool

      # Computed at access time so test stubs of `Dir.home` are respected.
      # @return [String]
      def self.default_yaml_path
        File.join(Dir.home, '.worklog')
      end

      # Build a StorageConfig from the parsed configuration hash.
      # Supports both the new nested `storage:` block and the legacy
      # top-level `storage_path:` key for backward compatibility.
      # @param file_cfg [Hash] The full parsed config hash from `~/.worklog.yaml`.
      # @return [StorageConfig] The constructed storage config.
      def self.from_hash(file_cfg)
        cfg = new
        storage_block = file_cfg['storage'] if file_cfg.is_a?(Hash)

        if storage_block.is_a?(Hash)
          cfg.engine = (storage_block['engine'] || 'yaml').to_sym
          yaml_block = storage_block['yaml'] || {}
          pg_block = storage_block['postgres'] || {}
          cfg.yaml_path = yaml_block['path'] || file_cfg['storage_path']
          cfg.postgres_url = pg_block['url']
          cfg.postgres_pool = pg_block['pool']
        else
          # Legacy: only `storage_path:` at the root, no `storage:` block.
          cfg.engine = :yaml
          cfg.yaml_path = file_cfg['storage_path'] if file_cfg.is_a?(Hash)
        end

        cfg.finalize!
        cfg
      end

      def initialize
        @engine = :yaml
        @yaml_path = nil
        @postgres_url = nil
        @postgres_pool = DEFAULT_POSTGRES_POOL
      end

      # Apply defaults and validate engine selection.
      # @return [void]
      def finalize!
        @engine = :yaml if @engine.nil?
        @engine = @engine.to_sym
        raise ArgumentError, "Unknown storage engine: #{@engine}" unless VALID_ENGINES.include?(@engine)

        @yaml_path ||= self.class.default_yaml_path
        @postgres_pool ||= DEFAULT_POSTGRES_POOL
        @postgres_url = resolve_env(@postgres_url) if @postgres_url
      end

      # Resolve `${ENV_VAR}` references in a URL string.
      # @param value [String]
      # @return [String]
      def resolve_env(value)
        value.gsub(/\$\{(\w+)\}/) { ENV.fetch(::Regexp.last_match(1), '') }
      end
    end

    # Configuration for projects
    # @!attribute [rw] show_last
    #   @return [Integer] Number of last projects to show in the project list.
    class ProjectConfig
      attr_accessor :show_last

      # Initialize with default values, parameters can be overridden via hash
      # @example
      #   ProjectConfig.new({'show_last' => 5})
      def initialize(params = {})
        return if params.nil?

        params.each do |key, value|
          instance_variable_set("@#{key}", value) if respond_to?("#{key}=")
        end
      end
    end

    # Configuration for Github API access.
    # @!attribute [rw] api_key
    #   @return [String] The API key for Github access.
    # @!attribute [rw] username
    #   @return [String] The Github username.
    class GithubConfig
      attr_accessor :api_key, :username

      # Initialize with default values, parameters can be overridden via hash
      # @example
      #   GithubConfig.new({'api_key' => '123abc', 'username' => 'sample-user'})
      def initialize(params = {})
        return if params.nil?

        params.each do |key, value|
          instance_variable_set("@#{key}", value) if respond_to?("#{key}=")
        end
      end
    end

    CONFIGURATION_TEMPLATE = ERB.new <<~YAML
      # Worklog Configuration File
      # This file contains configuration settings for Worklog.
      # You can modify the values below to customize your setup.
      # For more information, refer to the documentation.

      # Storage engine selection. Set `engine` to either `yaml` (default,
      # human-readable files on disk) or `postgres` (a PostgreSQL database).
      # Only the block matching the selected engine needs to be filled in.
      storage:
        engine: yaml
        yaml:
          path: <%= Dir.home %>/.worklog
        postgres:
          # Connection URL. Environment variables can be referenced with ${VAR}.
          url: "${WORKLOG_DATABASE_URL}"
          pool: 5

      log_level: info
      timezone: 'America/Los_Angeles'
      webserver_port: 3000

      project:
        # Number of last projects to show in the project list
        show_last: 3

      github:
        # Your GitHub API key for accessing the GitHub API
        api_key: ""
        # Your GitHub username for finding assigned issues and PRs
        username: ""
    YAML

    # Initialize configuration with optional block for setting attributes.
    # If no block is given, default values are used.
    # @example
    #   Configuration.new do |config|
    #     config.storage_path = '/custom/path'
    #     config.log_level = :debug
    #     config.timezone = 'America/Los_Angeles'
    #   end
    def initialize(&block)
      @storage = StorageConfig.new
      block&.call(self)

      # Set default values if not set
      @log_level ||= :info
      @log_level = @log_level.to_sym if @log_level.is_a?(String)
      @timezone ||= 'America/Los_Angeles'
      @timezone = TZInfo::Timezone.get(@timezone) if @timezone.is_a?(String)
      @webserver_port ||= 3000
      @project ||= ProjectConfig.new
      @github ||= GithubConfig.new
      @storage.finalize!
    end

    # Load configuration from a YAML file in the user's home directory.
    # If the file does not exist, it will use default values.
    # @return [Configuration] the loaded configuration
    def self.load
      file_path = config_file_path
      config = Configuration.new
      unless File.exist?(file_path)
        WorkLogger.debug "Configuration file does not exist in #{file_path}, using defaults."
        return config
      end

      file_cfg = YAML.load_file(file_path) || {}
      config.storage = StorageConfig.from_hash(file_cfg)
      config.log_level = file_cfg['log_level'].to_sym if file_cfg['log_level']
      config.webserver_port = file_cfg['webserver_port'] if file_cfg['webserver_port']
      config.timezone = TZInfo::Timezone.get(file_cfg['timezone']) if file_cfg['timezone']

      config.project = ProjectConfig.new(file_cfg['project'])
      config.github = GithubConfig.new(file_cfg['github'])

      config
    end

    # Storage engine selected for this run.
    # @return [Symbol] :yaml or :postgres
    def storage_engine
      @storage.engine
    end

    # YAML storage path (kept for backward compatibility with existing callers).
    # When the active engine is Postgres, this still returns the configured
    # YAML path, which is useful for `wl storage export`/`import`.
    # @return [String]
    def storage_path
      @storage.yaml_path
    end

    # Update the YAML storage path. Backward-compatible setter that
    # delegates to the nested StorageConfig.
    # @param value [String]
    def storage_path=(value)
      @storage.yaml_path = value
    end

    # Connection URL for the Postgres engine.
    # @return [String, nil]
    def postgres_url
      @storage.postgres_url
    end

    # Connection pool size for the Postgres engine.
    # @return [Integer]
    def postgres_pool
      @storage.postgres_pool
    end

    # Check if the storage path exists.
    # @return [Boolean] true if the storage path exists, false otherwise
    def storage_path_exist?
      File.exist?(storage_path)
    end

    # Check if the storage path is the default path.
    # @return [Boolean] true if the storage path is the default, false otherwise
    def default_storage_path?
      storage_path == File.join(Dir.home, '.worklog')
    end

    # Get the default configuration file path.
    # @return [String] the default configuration file path
    def self.config_file_path
      File.join(Dir.home, '.worklog.yaml')
    end
  end
end
