# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      module PostsHelper
        def editor_content_for(post, preserved_content = nil)
          content = preserved_content || post.content

          # Return empty structure if no content
          json_content = if content.blank?
            {blocks: []}.to_json
          # If content is already JSON string, use it
          elsif content.is_a?(String) && valid_json?(content)
            content
          # If it's a hash, convert to JSON
          elsif content.is_a?(Hash)
            content.to_json
          # Default to empty structure
          else
            {blocks: []}.to_json
          end

          # Base64 encode the JSON content
          Base64.strict_encode64(json_content)
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
