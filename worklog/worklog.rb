#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'hash'
require_relative 'daily_log'
require_relative 'log_entry'
require_relative 'storage'

require 'logger'
require 'optparse'
require 'rainbow'
require 'yaml'

# Initialize logger
$logger = Logger.new(STDOUT, level: Logger::Severity::INFO)

module Worklog

end
