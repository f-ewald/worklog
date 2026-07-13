# frozen_string_literal: true

require 'person'
require 'worklogger'

module Worklog
  module PeopleStorage
    # Abstract base class for people storage backends.
    class Base
      # @param config [Worklog::Configuration]
      def initialize(config)
        @config = config
      end

      # All known people, in arbitrary order.
      # @return [Array<Person>]
      def load_people
        raise NotImplementedError
      end

      # Same as {#load_people} but raises {Errno::ENOENT} when the
      # underlying store is missing. The YAML backend uses this to
      # signal "no people file present"; the Postgres backend returns
      # an empty array.
      # @return [Array<Person>]
      def load_people!
        raise NotImplementedError
      end

      # Replace all people in the backend with the given list.
      # @param people [Array<Person>]
      # @return [void]
      def write_people!(_people)
        raise NotImplementedError
      end

      # Optional: create a default file/template on first run.
      # @return [void]
      def create_default_file; end

      # All people keyed by handle.
      # @return [Hash{String=>Person}]
      def load_people_hash
        load_people.to_h { |person| [person.handle, person] }
      end

      # @param handle [String]
      # @return [Person, nil]
      def find_by_handle(handle)
        @people ||= load_people
        @people.find { |person| person.handle == handle }
      end

      # @param github_username [String]
      # @return [Person, nil]
      def find_by_github_username(github_username)
        @people ||= load_people
        @people.find { |person| person.github_username == github_username }
      end
    end
  end
end
