# frozen_string_literal: true

require 'digest'

module Worklog
  # Simple hashing utility
  class Hasher
    # Generate SHA256 hash for the given input string
    # @param input [String] The input string to hash
    # @param length [Integer] The length of the resulting hash (default: 7)
    # @return [String] The resulting SHA256 hash in hexadecimal format
    # @raise [ArgumentError] if length is not between 1 and 64
    def self.sha256(input, length = 7)
      raise ArgumentError, 'Length must be between 1 and 64' unless length.between?(1, 64)

      Digest::SHA256.hexdigest(input)[..(length - 1)]
    end
  end
end
