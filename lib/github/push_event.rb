# frozen_string_literal: true

require 'log_entry'

module Worklog
  module Github
    # Event representing a push event
    class PushEvent
      def to_log_entry
        WorkLogger.debug('Converting PushEvent to LogEntry')
        LogEntry.new(
          key: 'github-push-event',
          source: 'github',
          time: Time.now, # TODO: Fix this
          message: 'Push event occurred',
          url: nil
        )
      end
    end
  end
end
