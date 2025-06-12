# frozen_string_literal: true

module Panda
  module CMS
    class Slug
      #
      # Generates a slug from a provided string
      #
      # @param string [String] The provided string to turn into a slug
      # @return string Generated slug
      # @see slug_controller.js should also implement this logic
      def self.generate(string)
        # Trim whitespace and downcase the string
        string = string.to_s.strip.downcase
        # Replace & with "and"
        string = string.gsub("&", "and")
        # Remove special characters
        string = string.gsub(%r{[!@£\\\^\[\]/]+}, "")
        # Replace any whitespace character with -
        string = string.gsub(/[^\w\s-]/, "-")
        # Replace multiple occurences of _ and - with -
        string.gsub(/[\s_-]+/, "-")
      end
    end
  end
end
