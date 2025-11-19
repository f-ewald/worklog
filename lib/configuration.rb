# frozen_string_literal: true

require 'tzinfo'
require 'worklogger'
require 'yaml'

module Worklog
  # Configuration class for the application.
  # @!attribute [rw] storage_path
  #   @return [String] The path where the application stores its data.
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
  # @example Example ~/.worklog.yaml
  #   storage_path: /Users/username/.worklog
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
    attr_accessor :storage_path, :log_level, :timezone, :webserver_port, :project, :github

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

    # Initialize configuration with optional block for setting attributes.
    # If no block is given, default values are used.
    # @example
    #   Configuration.new do |config|
    #     config.storage_path = '/custom/path'
    #     config.log_level = :debug
    #     config.timezone = 'America/Los_Angeles'
    #   end
    def initialize(&block)
      block.call(self) if block_given?

      # Set default values if not set
      @storage_path ||= File.join(Dir.home, '.worklog')
      @log_level = log_level || :info
      @log_level = @log_level.to_sym if @log_level.is_a?(String)
      @timezone ||= 'America/Los_Angeles'
      @timezone = TZInfo::Timezone.get(@timezone) if @timezone.is_a?(String)
      @webserver_port ||= 3000
      @project = ProjectConfig.new
      @github = GithubConfig.new
    end

    # Load configuration from a YAML file in the user's home directory.
    # If the file does not exist, it will use default values.
    # @return [Configuration] the loaded configuration
    def self.load
      file_path = File.join(Dir.home, '.worklog.yaml')
      config = Configuration.new
      if File.exist?(file_path)
        file_cfg = YAML.load_file(file_path)
        config.storage_path = file_cfg['storage_path'] if file_cfg['storage_path']
        config.log_level = file_cfg['log_level'].to_sym if file_cfg['log_level']
        config.webserver_port = file_cfg['webserver_port'] if file_cfg['webserver_port']

        config.project = ProjectConfig.new(file_cfg['project'])
        config.github = GithubConfig.new(file_cfg['github'])
      else
        WorkLogger.debug "Configuration file does not exist in #{file_path}, using defaults."
      end

      config
    end

    # Check if the storage path exists.
    # @return [Boolean] true if the storage path exists, false otherwise
    def storage_path_exist?
      File.exist?(@storage_path)
    end

    # Check if the storage path is the default path.
    # @return [Boolean] true if the storage path is the default, false otherwise
    def default_storage_path?
      @storage_path == File.join(Dir.home, '.worklog')
    end
  end
end
