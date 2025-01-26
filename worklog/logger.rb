# frozen_string_literal: true

require 'logger'
require 'singleton'

# Singleton class for logging work log messages
class WorkLogger
  include Singleton

  def self.instance
    @instance ||= Logger.new($stdout)
  end

  def self.level=(level)
    instance.level = level
  end

  def self.info(message) = instance.info(message)
  def self.warn(message) = instance.warn(message)
  def self.error(message) = instance.error(message)
  def self.debug(message) = instance.debug(message)
end
