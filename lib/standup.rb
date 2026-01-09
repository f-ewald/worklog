# frozen_string_literal: true

require 'dotenv-vault/load'
require 'erb'
require 'faraday'
require 'langchain'
require 'openai'
require 'worklogger'

module Worklog
  # Generates standup prompts based on log entries.
  class Standup
    def initialize(entries)
      @entries = entries
    end

    # Generate the standup message.
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
      # assistant.add_message_callback = lambda { |message|
      #   WorkLogger.debug "New message: #{message.role} | #{message.content}"
      # }
      # assistant.tool_execution_callback = lambda { |tool_call_id, tool_name, method_name, tool_arguments|
      #   WorkLogger.debug "Executing tool_call_id: #{tool_call_id}, tool_name: #{tool_name}, method_name: #{method_name}, tool_arguments: #{tool_arguments}"
      # }

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
  end
end
