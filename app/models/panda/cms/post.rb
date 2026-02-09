# frozen_string_literal: true

require "awesome_nested_set"

module Panda
  module CMS
    class Post < ApplicationRecord
      include ::Panda::Editor::Content

      after_commit :clear_menu_cache
      before_validation :format_slug

      self.table_name = "panda_cms_posts"

      belongs_to :user, class_name: "Panda::Core::User"
      belongs_to :author, class_name: "Panda::Core::User", optional: true
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

      def self.editor_search(query, limit: 5)
        posts_prefix = Panda::CMS.config.posts[:prefix]
        where(status: :active)
          .where("title ILIKE :q OR slug ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
          .limit(limit)
          .map { |p| {href: "#{posts_prefix}#{p.slug}", name: p.title, description: "Post"} }
      end
      scope :with_user, -> { includes(:user) }
      scope :with_author, -> { includes(:author) }

      enum :status, {
        active: "active",
        draft: "draft",
        pending_review: "pending_review",
        hidden: "hidden",
        archived: "archived"
      }

      enum :seo_index_mode, {
        visible: "visible",
        invisible: "invisible"
      }, prefix: :seo

      enum :og_type, {
        website: "website",
        article: "article",
        profile: "profile",
        video: "video",
        book: "book"
      }, prefix: :og

      # Active Storage attachment for Open Graph image
      has_one_attached :og_image do |attachable|
        attachable.variant :og_share, resize_to_limit: [1200, 630]
      end

      # SEO validations
      validates :seo_title, length: {maximum: 70}, allow_blank: true
      validates :seo_description, length: {maximum: 160}, allow_blank: true
      validates :og_title, length: {maximum: 60}, allow_blank: true
      validates :og_description, length: {maximum: 200}, allow_blank: true
      validates :canonical_url, format: {with: URI::DEFAULT_PARSER.make_regexp(%w[http https])}, allow_blank: true

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

      #
      # Returns the effective SEO title for this post
      # Falls back to post title if not set
      #
      # @return [String] The SEO title to use
      # @visibility public
      #
      def effective_seo_title
        seo_title.presence || title
      end

      #
      # Returns the effective SEO description for this post
      # Falls back to excerpt if not set
      #
      # @return [String, nil] The SEO description to use
      # @visibility public
      #
      def effective_seo_description
        seo_description.presence || excerpt(160, squish: true)
      end

      #
      # Returns the effective Open Graph title
      # Falls back to SEO title, then post title
      #
      # @return [String] The OG title to use
      # @visibility public
      #
      def effective_og_title
        og_title.presence || effective_seo_title
      end

      #
      # Returns the effective Open Graph description
      # Falls back to SEO description or excerpt
      #
      # @return [String, nil] The OG description to use
      # @visibility public
      #
      def effective_og_description
        og_description.presence || effective_seo_description
      end

      #
      # Returns the effective canonical URL for this post
      # Falls back to the post's own URL if not explicitly set
      #
      # @return [String] The canonical URL to use
      # @visibility public
      #
      def effective_canonical_url
        canonical_url.presence || slug
      end

      #
      # Generates the robots meta tag content based on seo_index_mode
      #
      # @return [String] The robots meta tag content (e.g., "index, follow")
      # @visibility public
      #
      def robots_meta_content
        case seo_index_mode
        when "visible"
          "index, follow"
        when "invisible"
          "noindex, nofollow"
        else
          "index, follow" # Default fallback
        end
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
        return self.slug = "/#{slug}" if slug.match?(%r{\A\d{4}/\d{2}/[^/]+\z})

        # Handle the case where we have a date-prefixed slug (from JS)
        if (match = slug.match(/\A(\d{4})-(\d{2})-(.+)\z/))
          year = match[1]
          month = match[2]
          base_slug = match[3]
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
