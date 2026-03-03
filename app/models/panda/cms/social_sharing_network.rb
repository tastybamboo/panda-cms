# frozen_string_literal: true

module Panda
  module CMS
    class SocialSharingNetwork < ApplicationRecord
      self.table_name = "panda_cms_social_sharing_networks"

      REGISTRY = {
        "facebook" => {
          name: "Facebook",
          icon: "fab fa-facebook-f",
          color: "#1877F2",
          share_url: "https://www.facebook.com/sharer/sharer.php?u={url}"
        },
        "x" => {
          name: "X",
          icon: "fab fa-x-twitter",
          color: "#000000",
          share_url: "https://twitter.com/intent/tweet?url={url}&text={title}"
        },
        "linkedin" => {
          name: "LinkedIn",
          icon: "fab fa-linkedin-in",
          color: "#0A66C2",
          share_url: "https://www.linkedin.com/sharing/share-offsite/?url={url}"
        },
        "whatsapp" => {
          name: "WhatsApp",
          icon: "fab fa-whatsapp",
          color: "#25D366",
          share_url: "https://wa.me/?text={title}%20{url}"
        },
        "bluesky" => {
          name: "Bluesky",
          icon: "fab fa-bluesky",
          color: "#0085FF",
          share_url: "https://bsky.app/intent/compose?text={title}%20{url}"
        },
        "mastodon" => {
          name: "Mastodon",
          icon: "fab fa-mastodon",
          color: "#6364FF",
          share_url: "https://share.joinmastodon.org/?text={title}%20{url}"
        },
        "threads" => {
          name: "Threads",
          icon: "fab fa-threads",
          color: "#000000",
          share_url: "https://www.threads.net/intent/post?text={title}%20{url}"
        },
        "email" => {
          name: "Email",
          icon: "fa-solid fa-envelope",
          color: "#666666",
          share_url: "mailto:?subject={title}&body={url}"
        },
        "copy_link" => {
          name: "Copy Link",
          icon: "fa-solid fa-link",
          color: "#666666",
          share_url: nil
        }
      }.freeze

      validates :key, presence: true, uniqueness: true, inclusion: {in: REGISTRY.keys}
      validates :position, presence: true

      scope :enabled, -> { where(enabled: true).order(:position) }
      scope :ordered, -> { order(:position) }

      def self.register_all
        REGISTRY.each_with_index do |(key, _meta), index|
          find_or_create_by(key: key) do |network|
            network.position = index
          end
        end
      end

      def metadata
        REGISTRY[key]
      end

      def display_name
        metadata&.dig(:name) || key.titleize
      end

      def icon
        metadata&.dig(:icon)
      end

      def color
        metadata&.dig(:color)
      end

      def share_url_template
        metadata&.dig(:share_url)
      end

      def copy_link?
        key == "copy_link"
      end

      def build_share_url(title:, url:)
        return nil if copy_link?

        template = share_url_template
        return nil unless template

        template
          .gsub("{title}", ERB::Util.url_encode(title))
          .gsub("{url}", ERB::Util.url_encode(url))
      end
    end
  end
end
