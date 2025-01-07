# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      module PostsHelper
        def editor_content_for(post, preserved_content = nil)
          content = preserved_content || post.content

          # Return empty structure if no content
          return {blocks: []}.to_json if content.blank?

          # If content is already JSON string, return it
          return content if content.is_a?(String) && valid_json?(content)

          # If it's a hash, convert to JSON
          return content.to_json if content.is_a?(Hash)

          # Default to empty structure
          {blocks: []}.to_json
        end

        private

        def valid_json?(string)
          JSON.parse(string)
          true
        rescue JSON::ParserError
          false
        end
      end
    end
  end
end
