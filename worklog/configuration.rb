# frozen_string_literal: true

require 'yaml'

# Configuration class for the application.
class Configuration
  attr_accessor :storage_path, :log_level, :webserver_port

  def initialize(&block)
    block.call(self) if block_given?

    # Set default values if not set
    @storage_path ||= File.join(Dir.home, '.worklog')
    @log_level ||= :info
    @webserver_port ||= 3000
  end
end

def load_configuration
  # TODO: Implement loading configuration from a file
  if File.exist?(File.join(Dir.home, '.worklog.yaml'))
    file_cfg = YAML.load_file(File.join(Dir.home, '.worklog.yaml'))
    Configuration.new do |cfg|
      cfg.storage_path = file_cfg['storage_path'] if file_cfg['storage_path']
      cfg.log_level = file_cfg['log_level'].to_sym if file_cfg['log_level']
      cfg.webserver_port = file_cfg['webserver_port'] if file_cfg['webserver_port']
    end
  else
    puts 'File does not exist'
  end
end
