require "awesome_nested_set"

module Panda
  module CMS
    class Post < ApplicationRecord
      include ::Panda::CMS::EditorJsContent

      after_commit :clear_menu_cache

      self.table_name = "panda_cms_posts"

      has_paper_trail versions: {
        class_name: "Panda::CMS::PostVersion"
      }

      belongs_to :user, class_name: "Panda::CMS::User"
      belongs_to :author, class_name: "Panda::CMS::User"

      validates :title, presence: true
      validates :slug,
        presence: true,
        uniqueness: true,
        format: {
          with: %r{\A(/\d{4}/\d{2}/[a-z0-9-]+|/[a-z0-9-]+)\z},
          message: "must be in format /YYYY/MM/slug or /slug with only lowercase letters, numbers, and hyphens"
        }

      scope :ordered, -> { order(published_at: :desc) }
      scope :with_user, -> { includes(:user) }
      scope :with_author, -> { includes(:author) }

      enum :status, {
        active: "active",
        draft: "draft",
        hidden: "hidden",
        archived: "archived"
      }

      def to_param
        slug.delete_prefix("/")
      end

      def admin_param
        id
      end

      def excerpt(length = 100, squish: true)
        return "" if content.blank?

        text = if content.is_a?(Hash) && content["blocks"]
          content["blocks"]
            .select { |block| block["type"] == "paragraph" }
            .map { |block| block["data"]["text"] }
            .join(" ")
        else
          content.to_s
        end

        text = text.squish if squish
        text.truncate(length).html_safe
      end

      private

      def clear_menu_cache
        Rails.cache.delete("panda_cms_news_months")
      end
    end
  end
end
