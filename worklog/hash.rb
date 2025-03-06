# frozen_string_literal: true

module Hashify
  def to_hash
    hash = {}
    instance_variables.each do |var|
      value = instance_variable_get(var)
      hash[var.to_s.delete('@')] = value
    end
    hash
  end
end

class Hash
  # Convert all keys to strings so that the YAML file can be read from different languages.
  # This is a monkey patch to the Hash class.

  def stringify_keys
    # Convert all keys to strings.
    # This is useful when the hash is serialized to YAML.
    #
    # @return [Hash] the hash with all keys converted to strings
    map { |k, v| [k.to_s, v] }.to_h
  end
end
