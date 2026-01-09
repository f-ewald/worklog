# frozen_string_literal: true

require 'dotenv-vault/load'
require 'erb'
require 'faraday'
require 'langchain'
require 'openai'
require 'worklogger'
require 'log_entry_formatters'

module Worklog
  # Generates standup prompts based on log entries.
  # The Standup class takes log entries and people information to create a standup message that summarizes the work
  # done, work planned, and blockers.
  #
  # @example
  #   # Create log entries (or alternatively load from disk)
  #   entries = [LogEntry.new(...), LogEntry.new(...)]
  #
  #   # Create people information (or alternatively load from disk)
  #   people = { 'user1' => Person.new(...), 'user2' => Person.new(...) }
  #
  #   # Create a Standup instance and generate the standup message
  #   standup = Standup.new(entries, people)
  #   standup.generate
  class Standup
    # Initialize the Standup generator with log entries and people information.
    # If no people information is provided, identifiers will not be resolved to names.
    # @param entries [Array<LogEntry>] the log entries to include in the standup.
    # These entries can be either of a single day or span multiple days, depending on the desired output.
    # They are handled by the LLM to generate a standup message that summarizes the work done, work planned,
    # and blockers.
    # @param people [Hash<String, Person>] the people information to include in the standup
    def initialize(entries, people)
      @entries = entries
      @people = people
    end

    # Generate the standup message and print it to the console.
    # @return [nil] prints the generated standup message to the console.
    def generate
      Langchain.logger.level = Logger::WARN

      system_prompt, user_prompt = create_prompt

      llm = Langchain::LLM::OpenAI.new(api_key: ENV.fetch('OPENAI_API_KEY', nil),
                                       default_options: {
                                         chat_model: 'gpt-5.2' # or any other supported model
                                       })

      # Override the client to increase timeout
      def llm.client
        @client ||= Faraday.new(url: url, headers: auth_headers) do |conn|
          conn.options.timeout = 300
          conn.request :json
          conn.response :json
          conn.response :raise_error
          conn.response :logger, Langchain.logger, { headers: true, bodies: true, errors: true }
        end
      end

      assistant = Langchain::Assistant.new(
        llm: llm,
        instructions: system_prompt
      )

      assistant.add_message(role: 'user', content: user_prompt)

      WorkLogger.debug('Starting standup generation')
      begin
        assistant.run(auto_tool_execution: true)
      rescue Faraday::ForbiddenError => e
        WorkLogger.error("LLM request failed: #{e.response}")
        raise
      end
      WorkLogger.debug('Finished standup generation')
      puts Rainbow('Standup generated successfully!').yellow
      puts assistant.messages.last.content
    end

    # Create the system and user prompts for standup generation.
    # @return [Array<String>] the system prompt and user prompt.
    def create_prompt
      system_prompt_template = File.read(File.join(__dir__, '..', 'assets', 'prompts', 'standup.system.md.erb'))
      system_prompt = ERB.new(system_prompt_template, trim_mode: '-<>').result(binding)

      user_prompt_template = File.read(File.join(__dir__, '..', 'assets', 'prompts', 'standup.user.md.erb'))
      user_prompt = ERB.new(user_prompt_template, trim_mode: '-<>').result(binding)

      [system_prompt, user_prompt]
    end

    def formatted_entries
      formatter = LogEntryFormatters::SimpleFormatter.new(@people)
      @entries.map do |entry|
        entry.to_hash.slice(:epic, :ticket, :url).merge(message: formatter.format(entry))
      end
    end
  end
end
