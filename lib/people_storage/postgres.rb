# frozen_string_literal: true

require 'json'
require 'db'
require 'person'
require 'people_storage/base'
require 'worklogger'

module Worklog
  module PeopleStorage
    # Postgres-backed people storage. People live in the `people`
    # table; the `notes` column is `text[]` on Postgres and a
    # JSON-encoded string elsewhere.
    class Postgres < Base
      def initialize(config)
        super
        @db = ::Worklog::DB.connection(config)
        @uses_native_arrays = @db.database_type == :postgres
      end

      # @return [Array<Person>]
      def load_people
        load_people!
      end

      # The `!` variant exists for API parity with the YAML backend.
      # The Postgres backend simply returns an empty array when the
      # table is empty; there is no "missing store" condition.
      # @return [Array<Person>]
      def load_people!
        @db[:people].order(:handle).all.map { |row| row_to_person(row) }
      end

      # Replace all rows in `people` with the provided list.
      # @param people [Array<Person>]
      # @return [void]
      def write_people!(people)
        raise ArgumentError, 'people must be an array of Person objects' if people.nil? || !people.is_a?(Array)

        @db.transaction do
          @db[:people].delete
          people.each do |person|
            @db[:people].insert(
              handle: person.handle,
              name: person.name,
              github_username: person.github_username,
              email: person.email,
              team: person.team,
              notes: serialize_array(person.notes),
              inactive: person.inactive == true
            )
          end
        end
        @people = people
      end

      private

      # @param row [Hash]
      # @return [Person]
      def row_to_person(row)
        Person.new(
          handle: row[:handle],
          name: row[:name],
          github_username: row[:github_username],
          email: row[:email],
          team: row[:team],
          notes: deserialize_array(row[:notes]),
          inactive: row[:inactive] == true
        )
      end

      # @param value [Array<String>, nil]
      # @return [Array<String>, String, nil]
      def serialize_array(value)
        value = [] if value.nil?
        return value if @uses_native_arrays

        JSON.dump(value)
      end

      # @param value [Array<String>, String, nil]
      # @return [Array<String>]
      def deserialize_array(value)
        return [] if value.nil?
        return value if value.is_a?(Array)

        parsed = JSON.parse(value)
        parsed.is_a?(Array) ? parsed : []
      rescue JSON::ParserError
        []
      end
    end
  end
end
