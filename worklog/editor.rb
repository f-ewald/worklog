# frozen_string_literal: true

require 'erb'
require 'tempfile'

EDITOR_PREAMBLE = ERB.new <<~README
  # Edit the content below, then save the file and quit the editor.
  # The update content will be saved. The content MUST be valid YAML
  # in order for the application to be able to update the records.

  <%= content %>
README

# Editor to handle editing of log entries.
module Editor
  def self.open_editor(initial_text)
    file_handle = Tempfile.create
    file_handle.write(initial_text)
    file_handle.close

    # Open the editor with the temporary file.
    system('vim', file_handle.path)

    updated_text = nil

    # Read the updated text from the file.
    File.open(file_handle.path, 'r') do |f|
      updated_text = f.read
      WorkLogger.debug("Updated text: #{updated_text}")
    end
    File.unlink(file_handle.path)
    updated_text
  end
end
