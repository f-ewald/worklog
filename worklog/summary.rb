# frozen_string_literal: true

require 'erb'
require 'httparty'
require 'json'

module Summary
  MODEL = 'llama3.2'
  SUMMARY_INSTRUCTION = ERB.new <<~INSTRUCTION
    You are given a list of accomplishments during a time period.
    Each accomplishment is divided by comma.
    Bigger accomplishments are marked with the word "EPIC".
    Write a summary of the accomplishments in English and highlight the bigger accomplishments.
    This summary will be used as a basis for the performance review.
      <%= accomplishments %>
    Summary:
  INSTRUCTION

  SYSTEM_INSTRUCTION = <<~INSTRUCTION
    You are an AI assistant that generates summaries of accomplishments.
    The summary is based on a list of accomplishments.
    There is no limit to the number of accomplishments.
    The summary should be written in English, using the "I" form, and in complete sentences.
    Use a professional tone and avoid jargon.
    If something is ambiguous or unclear, use the text verbatim and do not try to interpret it.
    There are no preambles or greetings.
    Notable Accomplishments:
  INSTRUCTION


  def self.generate_summary(log_entries)
    entries = log_entries.map { |entry| entry.message }
    prompt = SUMMARY_INSTRUCTION.result_with_hash(accomplishments: entries.join(', '))

    begin
      response = HTTParty.post('http://localhost:11434/api/generate', 
        body: {
          model: Summary::MODEL,
          prompt: ,
          system: Summary::SYSTEM_INSTRUCTION,
          stream: false,
    }.to_json, 
        headers: { 'Content-Type' => 'application/json' }
      )
      response.parsed_response["response"]
    rescue Errno::ECONNREFUSED
      puts 'Ollama doesn\'t seem to be running. Please start the server and try again.'
    end
  end
end