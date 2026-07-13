# frozen_string_literal: true

require 'yaml'
require 'people_storage/base'
require 'person'
require 'worklogger'

module Worklog
  module PeopleStorage
    # YAML-backed people storage. All people live in a single
    # `people.yaml` file under `config.storage_path`.
    class Yaml < Base
      PEOPLE_FILE = 'people.yaml'

      # The template seeded when no people file exists yet.
      PERSON_TEMPLATE = <<~YAML
        ---
        # Each person is defined by the following attributes:
        # - handle: <unique_handle>
        #     Unique handle used to reference this person (e.g., ~jdoe)
        #   github_username: <github_username>
        #     GitHub username of the person, used to link GitHub events to this person.
        #     This can be omitted if the person does not have a GitHub account and can
        #     be different from the handle.
        #   name: <full_name>
        #   team: <team_name>
        #   email: <email_address>
        #   title: <title_or_role>
        #   inactive: <true_or_false>
        #   --- Define your people below this line ---
      YAML

      # Absolute path of the people.yaml file.
      # @return [String]
      def people_filepath
        File.join(@config.storage_path, PEOPLE_FILE)
      end

      # @return [Array<Person>]
      def load_people
        load_people!
      rescue Errno::ENOENT
        File.write(people_filepath, PERSON_TEMPLATE)
        []
      end

      # @return [Array<Person>]
      # @raise [Errno::ENOENT]
      def load_people!
        yamltext = File.read(people_filepath)
        yamltext = migrate_deprecated_syntax(yamltext)

        data = YAML.load(yamltext, permitted_classes: [])
        return [] unless data.is_a?(Array)

        data.map { |person_hash| Person.from_hash(person_hash) }
      end

      # @param people [Array<Person>]
      # @return [void]
      def write_people!(people)
        raise ArgumentError, 'people must be an array of Person objects' if people.nil? || !people.is_a?(Array)

        File.open(people_filepath, 'w') do |f|
          f.puts people.to_yaml
        end
        @people = people
      end

      # Write the people template if no file exists.
      # @return [void]
      def create_default_file
        if File.exist?(people_filepath)
          WorkLogger.info 'people.yaml already exists, skipping creation.'
          return
        end

        WorkLogger.info 'Creating default people.yaml file.'
        File.write(people_filepath, PERSON_TEMPLATE)
      end

      private

      # Rewrite the deprecated `- !ruby/object:...` prefix introduced
      # before v0.2.26 with the current `- ` notation. Persists the
      # cleanup back to disk to amortize the cost.
      # @param yamltext [String]
      # @return [String]
      def migrate_deprecated_syntax(yamltext)
        return yamltext if yamltext == yamltext.gsub(/^- !.*$/, '-')

        WorkLogger.debug 'The people.yaml file contains deprecated syntax. Migrating now.'
        migrated = yamltext.gsub(/^- !.*$/, '-')
        File.write(people_filepath, migrated)
        migrated
      end
    end
  end
end
