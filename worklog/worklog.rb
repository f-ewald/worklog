# frozen_string_literal: true

require 'hash'
require 'daily_log'
require 'log_entry'
require 'storage'

require 'logger'
require 'optparse'
require 'rainbow'
require 'yaml'

# Initialize logger
$logger = Logger.new(STDOUT, level: Logger::Severity::INFO)

module Worklog

end
