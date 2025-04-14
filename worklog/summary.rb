# frozen_string_literal: true

require 'erb'
require 'httparty'
require 'json'

require_relative 'logger'

# AI Summary generation.
module Summary
  MODEL = 'llama3.2'
  SUMMARY_INSTRUCTION = <<~INSTRUCTION
    <% entries.each do |entry| -%>
    <%= entry.message %>
    <% end -%>
  INSTRUCTION

  SYSTEM_INSTRUCTION = <<~INSTRUCTION
    You are a professional summarization assistant specialized in crafting performance review summaries. Your role is to take a list of achievements provided by the user and generate a concise, professional summary suitable for use in a formal performance review.

    Guidelines:

    Accuracy: Do not invent or infer any facts not explicitly provided by the user. Use only the information given.
    Tone: Maintain a formal, professional tone throughout the summary.
    Structure: Organize the summary in a coherent manner, emphasizing key accomplishments and their impact.
    Clarity: Use clear and concise language, avoiding jargon unless specified by the user.
    Your Task:

    Analyze the list of achievements provided by the user.
    Identify the key themes and accomplishments.
    Draft a polished summary that highlights the individual’s contributions and results.
    Constraints:

    Do not fabricate details or add context that has not been explicitly stated.
    Always prioritize clarity and professionalism in your writing.
    Example Input:

    "Exceeded sales targets by 15% in Q3."
    "Implemented a new CRM system, reducing customer response time by 30%."
    "Mentored two junior team members, both of whom received promotions."
    Example Output: "[Name] demonstrated outstanding performance during the review period. Key accomplishments include exceeding sales targets by 15% in Q3, implementing a new CRM system that improved customer response times by 30%, and mentoring two junior team members who achieved career advancements. These achievements highlight [Name]'s exceptional contributions to team success and organizational growth."
  INSTRUCTION

  # Build the prompt from provided log entries.
  def self.build_prompt(log_entries)
    ERB.new(SUMMARY_INSTRUCTION, trim_mode: '-').result_with_hash(entries: log_entries)
  end

  # Generate a summary from provided log entries.
  # @param log_entries [Array<LogEntry>] The log entries to summarize.
  # @return [String] The generated summary.
  def self.generate_summary(log_entries)
    prompt = build_prompt(log_entries)

    WorkLogger.debug("Using prompt: #{prompt}")

    begin
      response = HTTParty.post('http://localhost:11434/api/generate',
                               body: {
                                 model: Summary::MODEL,
                                 prompt:,
                                 system: Summary::SYSTEM_INSTRUCTION,
                                 stream: false
                               }.to_json,
                               headers: { 'Content-Type' => 'application/json' })
      response.parsed_response['response']
    rescue Errno::ECONNREFUSED
      WorkLogger.error <<~MSG
        Ollama doesn't seem to be running. Please start the server and try again.
        puts 'You can download Ollama at https://ollama.com'
      MSG
    end
  end
end
