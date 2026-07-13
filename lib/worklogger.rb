# frozen_string_literal: true

require 'fileutils'
require 'logger'
require 'singleton'

# Singleton class for logging work log messages
class WorkLogger
  include Singleton

  def self.instance
    @instance ||= Logger.new($stdout)
  end

  # Redirect logging to a rotating file instead of $stdout.
  # Used by the worklogd background agent; the `wl` CLI keeps logging to stdout
  # because it never calls this method.
  # @param path [String] Absolute path of the log file. Parent directories are created.
  # @param shift_age [String, Integer] Rotation period or retained-file count (daily by default).
  # @return [Logger] The newly installed file logger.
  def self.log_to_file(path, shift_age = 'daily')
    FileUtils.mkdir_p(File.dirname(path))
    file_logger = Logger.new(path, shift_age)
    file_logger.level = instance.level
    @instance = file_logger
  end

  def self.level=(level)
    instance.level = level
  end

  def self.level
    instance.level
  end

  def self.info(message) = instance.info(message)
  def self.warn(message) = instance.warn(message)
  def self.error(message) = instance.error(message)
  def self.debug(message) = instance.debug(message)
end
