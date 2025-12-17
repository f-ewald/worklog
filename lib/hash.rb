# frozen_string_literal: true

module Hashify
  # Convert the object's instance variables to a hash.
  # @return [Hash] the hash representation of the object
  def to_hash
    instance_variables.each_with_object({}) do |var, hash|
      key = var.to_s.delete('@').to_sym
      hash[key] = instance_variable_get(var)
    end
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
