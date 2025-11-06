# frozen_string_literal: true

require 'zlib'
require 'rubygems/package'
require 'stringio'

module Worklog
  # Exporter for worklog entries to a compressed tarball.
  class Takeout
    # Constructor
    # @param configuration [Configuration] The application configuration
    def initialize(configuration)
      @configuration = configuration
    end

    # Retrieves all files from the storage path.
    # @return [Array<String>] List of file paths
    def all_files
      Dir.glob(File.join(@configuration.storage_path, '*')).select { |file| File.file?(file) }
    end

    # Creates a tar.gz archive of all worklog files, including settings.
    # @return [String] The tar.gz data as a binary string
    def to_tar_gz
      tar_io = StringIO.new

      Gem::Package::TarWriter.new(tar_io) do |tar|
        all_files.each do |file_path|
          file_name = File.basename(file_path)
          File.open(file_path, 'rb') do |file|
            stat = file.stat
            tar.add_file(file_name, stat.mode, stat.mtime) do |tar_file|
              IO.copy_stream(file, tar_file)
            end
          end
        end
      end

      # Compress the tar data with gzip
      gz_io = StringIO.new
      Zlib::GzipWriter.wrap(gz_io) do |gzip|
        tar_io.rewind
        IO.copy_stream(tar_io, gzip)
      end
      gz_io.rewind

      gz_io.string
    end
  end
end
