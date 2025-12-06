# frozen_string_literal: true

# require "http"
# require "down"

module Panda
  module Social
    class InstagramFeedService
      #       GRAPH_API_VERSION = "v19.0"
      #       GRAPH_API_BASE_URL = "https://graph.instagram.com/#{GRAPH_API_VERSION}".freeze

      #       def initialize(access_token)
      #         @access_token = access_token
      #       end

      #       def sync_recent_posts
      #         fetch_media.each do |post_data|
      #           process_post(post_data)
      #         end
      #       end

      #       private

      #       def fetch_media
      #         response = HTTP.get("#{GRAPH_API_BASE_URL}/me/media", params: {
      #           access_token: @access_token,
      #           fields: "id,caption,media_type,media_url,permalink,timestamp"
      #         })

      #         return [] unless response.status.success?

      #         JSON.parse(response.body.to_s)["data"]
      #       end

      #       def process_post(post_data)
      #         return unless post_data["media_type"] == "IMAGE"

      #         instagram_post = InstagramPost.find_or_initialize_by(instagram_id: post_data["id"])

      #         instagram_post.assign_attributes(
      #           caption: post_data["caption"],
      #           posted_at: Time.zone.parse(post_data["timestamp"]),
      #           permalink: post_data["permalink"]
      #         )

      #         if instagram_post.new_record? || instagram_post.changed?
      #           # Download and attach image
      #           tempfile = Down.download(post_data["media_url"])
      #           instagram_post.image.attach(
      #             io: tempfile,
      #             filename: File.basename(post_data["media_url"])
      #           )

      #           instagram_post.save!
      #         end
      #       rescue Down::Error => e
      #         Rails.logger.error "Failed to download Instagram image: #{e.message}"
      #       rescue => e
      #         Rails.logger.error "Error processing Instagram post #{post_data["id"]}: #{e.message}"
      #       end
    end
  end
end
