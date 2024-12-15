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
              preserved_content.is_a?(String) ? JSON.parse(preserved_content) : preserved_content
            rescue JSON::ParserError => e
              Rails.logger.error "Failed to parse preserved content: #{e.message}"
              post.content
            end
          else
            post.content
          end

          Rails.logger.debug "Using content: #{content.inspect}"

          # Ensure we have a valid editor content structure
          content = if content.blank? || !content.is_a?(Hash) || !content.key?("blocks")
            Rails.logger.debug "Creating new editor content structure"
            {
              time: Time.now.to_i * 1000,
              blocks: [],
              version: "2.28.2"
            }
          else
            # Ensure we have all required fields
            Rails.logger.debug "Ensuring required fields are present"
            content["time"] ||= Time.now.to_i * 1000
            content["version"] ||= "2.28.2"
            content["blocks"] ||= []
            content
          end

          json = content.to_json
          Rails.logger.debug "Returning JSON: #{json}"
          json
        end
      end
    end
  end
end
