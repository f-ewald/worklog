# frozen_string_literal: true

require 'person'
require 'worklogger'
require 'yaml'

module Worklog
  # Finding, reading, and writing of people
  # @see Person
  # @see Storage
  class PeopleStorage
    PEOPLE_FILE = 'people.yaml'

    # The template for the people YAML file.
    # This template is used to create a new people file if it does not exist.
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

    def initialize(config)
      @config = config
    end

    # Return the full absolute filepath for the people.yaml file
    # @return [String] The filepath
    def people_filepath
      File.join(@config.storage_path, PEOPLE_FILE)
    end

    # Load all people from the people file and return them as a hash with handle as key
    # @return [Hash<String, Person>] Hash of people with handle as key
    def load_people_hash
      load_people.to_h { |person| [person.handle, person] }
    end

    # Load all people from the people YAML file
    # Return empty array if file does not exist
    # @return [Array<Person>] List of all people
    def load_people
      load_people!
    rescue Errno::ENOENT
      # If the file does not exist, create it with the template
      File.write(people_filepath, PERSON_TEMPLATE)
      []
    end

    # Load all people from the people YAML file
    # @return [Array<Person>] List of all people
    # @raise [Errno::ENOENT] if the people file does not exist
    def load_people!
      # TODO: Remove this migration code in future versions
      # This was introduced in v0.2.26 (Oct 2 2025) to fix deprecated YAML syntax
      yamltext = File.read(people_filepath)
      if yamltext != yamltext.gsub(/^- !.*$/, '-')
        WorkLogger.debug 'The people.yaml file contains deprecated syntax. Migrating now.'
        yamltext.gsub!(/^- !.*$/, '-')
        File.write(people_filepath, yamltext)
      end
      # End TODO

      data = YAML.load(yamltext, permitted_classes: [])
      return [] unless data.is_a?(Array)

      data.map { |person_hash| Person.from_hash(person_hash) }
    end

    # Write people to the people file
    # @param [Array<Person>] people List of people
    def write_people!(people)
      raise ArgumentError, 'people must be an array of Person objects' if people.nil? || !people.is_a?(Array)

      File.open(people_filepath, 'w') do |f|
        f.puts people.to_yaml
      end
      @people = people
    end

    # Create the default people file if it does not exist
    # @return [void]
    def create_default_file
      if File.exist?(people_filepath)
        WorkLogger.info 'people.yaml already exists, skipping creation.'
      else
        WorkLogger.info 'Creating default people.yaml file.'
        File.write(people_filepath, PERSON_TEMPLATE)
      end
    end

    # Find a person by their handle
    # @param [String] handle The handle of the person
    # @return [Person, nil] The person if found, nil otherwise
    def find_by_handle(handle)
      @people ||= load_people
      @people.find { |person| person.handle == handle }
    end

    # Find a person by their GitHub username
    # @param [String] github_username The GitHub username of the person
    # @return [Person, nil] The person if found, nil otherwise
    def find_by_github_username(github_username)
      @people ||= load_people
      @people.find { |person| person.github_username == github_username }
    end
  end
end
