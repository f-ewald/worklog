# frozen_string_literal: true

require 'pathname'

# Returns the current version of the gem from `.version`.
# Versioning follows SemVer.
# @return [String] The current version of the gem.
def current_version
  version_file_path = File.join(Pathname.new(__dir__).parent, '.version')
  File.read(version_file_path).strip
end

# Increment version number according to SemVer.
# @param version [String] The current version.
# @param part [String] The part of the version to increment.
# @return [String] The incremented version.
def increment_version(version, part = 'patch')
  major, minor, patch = version.split('.').map(&:to_i)
  case part
  when 'major'
    major += 1
    minor = 0
    patch = 0
  when 'minor'
    minor += 1
    patch = 0
  when 'patch'
    patch += 1
  end
  [major, minor, patch].join('.')
end
