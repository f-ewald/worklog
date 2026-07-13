# frozen_string_literal: true

require 'json'
require 'db'
require 'project'
require 'project_storage/base'

module Worklog
  module ProjectStorage
    # Postgres-backed project storage. Projects live in the `projects`
    # table; the `repositories` column is `jsonb` on Postgres and a
    # JSON-encoded string elsewhere.
    class Postgres < Base
      def initialize(config)
        super
        @db = ::Worklog::DB.connection(config)
        @uses_native_jsonb = @db.database_type == :postgres
      end

      # @return [Hash{String=>Project}]
      def load_projects
        @db[:projects].order(:key).all.each_with_object({}) do |row, acc|
          project = Project.from_hash(
            key: row[:key],
            name: row[:name],
            description: row[:description],
            start_date: row[:start_date],
            end_date: row[:end_date],
            status: row[:status],
            repositories: deserialize_repositories(row[:repositories])
          )
          acc[project.key] = project
        end
      end

      # Replace all rows in `projects` with the provided list.
      # @param projects [Array<Project>]
      # @return [void]
      def write_projects!(projects)
        raise ArgumentError, 'projects must be an array of Project objects' if projects.nil? || !projects.is_a?(Array)

        @db.transaction do
          @db[:projects].delete
          projects.each do |project|
            @db[:projects].insert(
              key: project.key,
              name: project.name,
              description: project.description,
              start_date: project.start_date,
              end_date: project.end_date,
              status: project.status,
              repositories: serialize_repositories(project.repositories)
            )
          end
        end
        @projects = projects.to_h { |project| [project.key, project] }
      end

      private

      # Repositories are stored as an array of "owner/name" strings.
      # @param repositories [Array<Github::Repository>, nil]
      # @return [Object]
      def serialize_repositories(repositories)
        values = Array(repositories).map(&:to_s)
        return values if @uses_native_jsonb

        JSON.dump(values)
      end

      # @param value [Object]
      # @return [Array<String>]
      def deserialize_repositories(value)
        return [] if value.nil?
        return value if value.is_a?(Array)

        parsed = JSON.parse(value.to_s)
        parsed.is_a?(Array) ? parsed : []
      rescue JSON::ParserError
        []
      end
    end
  end
end
