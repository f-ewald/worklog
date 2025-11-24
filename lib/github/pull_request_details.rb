# frozen_string_literal: true

module Worklog
  module Github
    # Details of a pull request, used internally
    PullRequestDetails = Struct.new('PullRequestDetails', :title, :description, :creator, :url, :state, :merged,
                                    :created_at, :merged_at, :closed_at, keyword_init: true) do
                                      def merged?
                                        state == 'closed' && merged == true
                                      end
                                    end
  end
end
