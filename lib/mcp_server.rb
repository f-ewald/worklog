# frozen_string_literal: true

require 'fast_mcp'
require 'json'

require 'configuration'
require 'worklog'
require 'people_storage'
require 'project_storage'
require 'storage'

require 'mcp/date_helper'
require 'mcp/entry_serializer'
require 'mcp/tools/query_entries_tool'
require 'mcp/tools/search_entries_tool'
require 'mcp/tools/list_tags_tool'
require 'mcp/tools/list_epics_tool'
require 'mcp/tools/list_people_tool'
require 'mcp/tools/list_projects_tool'
require 'mcp/tools/get_statistics_tool'
require 'mcp/resources/people_resource'
require 'mcp/resources/projects_resource'

module Worklog
  # Module-level singleton holding shared state for MCP tools and resources.
  # Set once at server startup, read by all tools. This avoids class metaprogramming
  # since fast-mcp creates tool instances internally.
  module McpContext
    class << self
      # @return [Configuration] The worklog configuration
      attr_accessor :config

      # @return [Storage] The worklog storage for querying daily logs
      attr_accessor :storage

      # @return [PeopleStorage] Storage for loading people data
      attr_accessor :people_storage

      # @return [ProjectStorage] Storage for loading project data
      attr_accessor :project_storage

      # @return [Hash<String, Person>] Hash of people keyed by handle
      attr_accessor :people
    end
  end

  # MCP server for exposing worklog data to LLMs via the Model Context Protocol.
  # Starts a stdio-based server that registers read-only tools and resources.
  class McpServer
    # Initialize the MCP server with worklog configuration and shared context.
    def initialize
      @config = Configuration.load
      @storage = Storage.new(@config)
      @people_storage = PeopleStorage.new(@config)
      @project_storage = ProjectStorage.new(@config)

      McpContext.config = @config
      McpContext.storage = @storage
      McpContext.people_storage = @people_storage
      McpContext.project_storage = @project_storage
      McpContext.people = @people_storage.load_people_hash
    end

    # Start the MCP server. This blocks and communicates over stdin/stdout.
    # @return [void]
    def start
      $stdout.sync = true

      server = FastMcp::Server.new(name: 'worklog', version: current_version)

      server.register_tools(
        Mcp::QueryEntriesTool,
        Mcp::SearchEntriesTool,
        Mcp::ListTagsTool,
        Mcp::ListEpicsTool,
        Mcp::ListPeopleTool,
        Mcp::ListProjectsTool,
        Mcp::GetStatisticsTool
      )

      server.register_resources(
        Mcp::PeopleResource,
        Mcp::ProjectsResource
      )

      server.start
    end

    private

    # @return [String] The current version from the .version file
    def current_version
      require 'version'
      Kernel.method(:current_version).call
    end
  end
end
