# frozen_string_literal: true

require 'worklogger'
require 'yaml'

module Worklog
  # Configuration class for the application.
  class Configuration
    attr_accessor :storage_path, :log_level, :webserver_port

    def initialize(&block)
      block.call(self) if block_given?

      # Set default values if not set
      @storage_path ||= File.join(Dir.home, '.worklog')
      @log_level = log_level || :info
      @log_level = @log_level.to_sym if @log_level.is_a?(String)
      @webserver_port ||= 3000
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
      else
        WorkLogger.debug "Configuration file does not exist in #{file_path}, using defaults."
      end

      config
    end
  end
end
