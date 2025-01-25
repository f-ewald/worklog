# frozen_string_literal: true

module Hashify
  def to_hash
    hash = {}
    instance_variables.each do |var|
      value = instance_variable_get(var)
      hash[var.to_s.delete("@")] = value
    end
    hash
  end
end

class Hash
  # Convert all keys to strings so that the YAML file can be read from different languages

  def stringify_keys
    self.map { |k, v| [k.to_s, v] }.to_h
  end
end
