# frozen_string_literal: true
# typed: true

# Helpers for String manipulation
module StringHelper
  # Pluralize a word based on a count. If the plural form is irregular, it can be provided.
  # Otherwise, it will be generated automatically.
  #
  # @param count [Integer] the count to base the pluralization on
  # @param singular [String] the singular form of the word
  # @param plural [String] the plural form of the word, if it is irregular. Otherwise it will be generated.
  # @return [String] the pluralized word
  def pluralize(count, singular, plural = nil)
    if count == 1
      singular
    else
      return plural if plural

      return "#{singular[0..-2]}ies" if singular.end_with? 'y'

      return "#{singular}es" if singular.end_with? 'ch', 's', 'sh', 'x', 'z'

      return "#{singular[0..-2]}ves" if singular.end_with? 'f', 'fe'

      "#{singular}s"
    end
  end
end
