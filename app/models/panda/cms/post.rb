require "awesome_nested_set"

module Panda
  module CMS
    class Post < ApplicationRecord
      include ::Panda::CMS::EditorJsContent

      after_commit :clear_menu_cache
      before_validation :format_slug

      self.table_name = "panda_cms_posts"

      belongs_to :user, class_name: "Panda::CMS::User"
      belongs_to :author, class_name: "Panda::CMS::User", optional: true
      has_many :block_contents, as: :blockable, dependent: :destroy
      has_many :blocks, through: :block_contents

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
        # For date-based URLs, return just the slug portion
        parts = CGI.unescape(slug).delete_prefix("/").split("/")
        if parts.length == 3 # year/month/slug format
          parts.last
        else
          parts.first
        end
      end

      def year
        return nil unless slug.match?(%r{\A/\d{4}/})
        slug.split("/")[1]
      end

      def month
        return nil unless slug.match?(%r{\A/\d{4}/\d{2}/})
        slug.split("/")[2]
      end

      def route_params
        if year && month
          {year: year, month: month, slug: to_param}
        else
          {slug: to_param}
        end
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

      def format_slug
        return if slug.blank?

        # Remove any leading/trailing slashes and decode
        self.slug = CGI.unescape(slug.strip.gsub(%r{^/+|/+$}, ""))

        # Handle the case where we already have a properly formatted slug
        if slug.match?(%r{\A\d{4}/\d{2}/[^/]+\z})
          return self.slug = "/#{slug}"
        end

        # Handle the case where we have a date-prefixed slug (from JS)
        if (match = slug.match(%r{\A(\d{4})-(\d{2})-(.+)\z}))
          year, month, base_slug = match[1], match[2], match[3]
          return self.slug = "/#{year}/#{month}/#{base_slug}"
        end

        # For new slugs without any date structure
        base_slug = slug.downcase.gsub(/[^a-z0-9-]+/, "-").gsub(/^-+|-+$/, "")
        date_prefix = published_at.present? ? published_at.strftime("%Y/%m") : Time.current.strftime("%Y/%m")
        self.slug = "/#{date_prefix}/#{base_slug}"
      end
    end
  end
end
