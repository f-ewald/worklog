# frozen_string_literal: true

require 'erb'
require 'tempfile'

# Editor to handle editing of log entries.
module Editor
  EDITOR_PREAMBLE = ERB.new <<~README
    # Edit the content below, then save the file and quit the editor.
    # The update content will be saved. The content MUST be valid YAML
    # in order for the application to be able to update the records.

    <%= content %>
  README

  # Open text editor (currently ViM) with the initial text.
  # Upon saving and exiting the editor, the updated text is returned.
  # @param initial_text [String] The initial text to display in the editor.
  # @return [String] The updated text.
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
