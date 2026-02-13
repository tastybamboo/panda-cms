# frozen_string_literal: true

require "faraday"
require "down"

module Panda
  module Social
    class InstagramFeedService
      GRAPH_API_VERSION = "v19.0"
      GRAPH_API_BASE_URL = "https://graph.instagram.com/#{GRAPH_API_VERSION}"

      def initialize(access_token)
        @access_token = access_token
        @connection = Faraday.new(url: GRAPH_API_BASE_URL) do |f|
          f.request :url_encoded
          f.response :json
          f.adapter Faraday.default_adapter
        end
      end

      def sync_recent_posts
        fetch_media.each do |post_data|
          process_post(post_data)
        end
      end

      private

      def fetch_media
        response = @connection.get("me/media", {
          access_token: @access_token,
          fields: "id,caption,media_type,media_url,permalink,timestamp"
        })

        return [] unless response.success?

        response.body["data"] || []
      end

      def process_post(post_data)
        return unless post_data["media_type"] == "IMAGE"

        instagram_post = InstagramPost.find_or_initialize_by(instagram_id: post_data["id"])

        instagram_post.assign_attributes(
          caption: post_data["caption"],
          posted_at: Time.zone.parse(post_data["timestamp"]),
          permalink: post_data["permalink"]
        )

        if instagram_post.new_record? || instagram_post.changed?
          tempfile = Down.download(post_data["media_url"])
          instagram_post.image.attach(
            io: tempfile,
            filename: File.basename(post_data["media_url"])
          )

          instagram_post.save!
        end
      rescue Down::Error => e
        Rails.logger.error "Failed to download Instagram image: #{e.message}"
      rescue => e
        Rails.logger.error "Error processing Instagram post #{post_data["id"]}: #{e.message}"
      end
    end
  end
end
