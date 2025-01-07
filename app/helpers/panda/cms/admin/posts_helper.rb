module Panda
  module CMS
    module Admin
      module PostsHelper
        def editor_content_for(post, preserved_content = nil)
          Rails.logger.debug "Editor content for post: #{post.inspect}"
          Rails.logger.debug "Preserved content: #{preserved_content.inspect}"
          Rails.logger.debug "Post content: #{post.content.inspect}"

          content = if preserved_content.present?
            # If preserved_content is a string (JSON), parse it
            begin
              if preserved_content.is_a?(String)
                # Try to parse as JSON first
                JSON.parse(preserved_content)
              elsif preserved_content.is_a?(Hash)
                # Convert Ruby hash keys to strings
                preserved_content.deep_transform_keys(&:to_s)
              else
                preserved_content
              end
            rescue JSON::ParserError => e
              Rails.logger.error "Failed to parse preserved content: #{e.message}"
              post.content
            end
          else
            post.content
          end

          # Always ensure we have a valid EditorJS structure
          content = if content.blank? || content == "{}" || (content.is_a?(Hash) && content.empty?)
            {
              "time" => Time.current.to_i * 1000,
              "blocks" => [
                {
                  "type" => "paragraph",
                  "data" => {
                    "text" => ""
                  }
                }
              ],
              "version" => "2.28.2"
            }
          elsif content.is_a?(Hash)
            # Ensure all keys are strings
            content = content.deep_transform_keys(&:to_s)
            if content["blocks"].present?
              content
            else
              {
                "time" => Time.current.to_i * 1000,
                "blocks" => [
                  {
                    "type" => "paragraph",
                    "data" => {
                      "text" => content.to_s
                    }
                  }
                ],
                "version" => "2.28.2"
              }
            end
          else
            {
              "time" => Time.current.to_i * 1000,
              "blocks" => [
                {
                  "type" => "paragraph",
                  "data" => {
                    "text" => content.to_s
                  }
                }
              ],
              "version" => "2.28.2"
            }
          end

          # Return the content as JSON string
          content.to_json
        end
      end
    end
  end
end
