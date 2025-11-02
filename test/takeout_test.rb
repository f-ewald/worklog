# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'
require 'takeout'

class TakeoutTest < Minitest::Test
  def test_initialize
    takeout = Worklog::Takeout.new(nil)
    assert_instance_of Worklog::Takeout, takeout
  end

  def test_all_files
    config = Worklog::Configuration.new do |cfg|
      cfg.storage_path = File.join(__dir__, 'data')
    end
    takeout = Worklog::Takeout.new(config)
    files = takeout.all_files
    expected_files = [
      File.join(__dir__, 'data', 'projects.yml'),
    ]
    assert_equal expected_files.sort, files.sort
  end

  def test_to_tar_gz
    config = Worklog::Configuration.new do |cfg|
      cfg.storage_path = File.join(__dir__, 'data')
    end
    takeout = Worklog::Takeout.new(config)
    tar_gz_data = takeout.to_tar_gz
    assert tar_gz_data.is_a?(String)
    assert tar_gz_data.length > 0

    # Write the tar.gz data to a temporary file and verify its contents
    Dir.mktmpdir do |dir|
      temp_file = File.join(dir, 'takeout.tar.gz')
      File.open(temp_file, 'wb') { |f| f.write(tar_gz_data) }

      # Extract the tar.gz file and verify the contents
      extracted_files = []
      Zlib::GzipReader.open(temp_file) do |gz|
        Gem::Package::TarReader.new(gz) do |tar|
          tar.each do |entry|
            extracted_files << entry.full_name
          end
        end
      end

      assert_includes extracted_files, 'projects.yml'
    end
  end
end
