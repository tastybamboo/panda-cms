# frozen_string_literal: true

require "awesome_nested_set"

module Panda
  module CMS
    class Page < ApplicationRecord
      acts_as_nested_set counter_cache: :children_count
      self.table_name = "panda_cms_pages"
      self.implicit_order_column = "lft"

      belongs_to :template, class_name: "Panda::CMS::Template", foreign_key: :panda_cms_template_id
      has_many :block_contents, class_name: "Panda::CMS::BlockContent", foreign_key: :panda_cms_page_id,
        dependent: :destroy
      has_many :blocks, through: :block_contents
      has_many :menu_items, foreign_key: :panda_cms_page_id, class_name: "Panda::CMS::MenuItem", inverse_of: :page
      has_many :menus, through: :menu_items
      has_many :menus_of_parent, through: :parent, source: :menus
      has_one :page_menu, foreign_key: :start_page_id, class_name: "Panda::CMS::Menu"

      validates :title, presence: true

      validates :path,
        presence: true,
        format: {with: %r{\A/.*\z}, message: "must start with a forward slash"}

      validate :validate_unique_path_in_scope

      validates :parent,
        presence: true,
        unless: -> { path == "/" }

      validates :panda_cms_template_id,
        presence: true

      scope :ordered, -> { order(:lft) }

      enum :status, {
        active: "active",
        draft: "draft",
        pending_review: "pending_review",
        hidden: "hidden",
        archived: "archived"
      }

      enum :page_type, {
        standard: "standard",
        hidden_type: "hidden",
        system: "system",
        posts: "posts",
        code: "code"
      }, prefix: :type

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

      # Callbacks
      after_save :handle_after_save
      before_save :update_cached_last_updated_at

      #
      # Update any menus which include this page or its parent as a menu item
      #
      # @return nil
      # @visibility public
      #
      def update_auto_menus
        menus.find_each(&:generate_auto_menu_items)
        menus_of_parent.find_each(&:generate_auto_menu_items)
      end

      #
      # Returns the most recent update time between the page and its block contents
      # Uses cached value for performance
      #
      # @return [Time] The most recent updated_at timestamp
      # @visibility public
      #
      def last_updated_at
        cached_last_updated_at || updated_at
      end

      #
      # Refresh the cached last updated timestamp
      # Used when block contents are updated
      #
      # @return [Time] The updated timestamp
      # @visibility public
      #
      def refresh_last_updated_at!
        block_content_updated_at = block_contents.maximum(:updated_at)
        new_timestamp = [updated_at, block_content_updated_at].compact.max
        update_column(:cached_last_updated_at, new_timestamp)
        new_timestamp
      end

      #
      # Returns the effective SEO title for this page
      # Falls back to page title if not set, with optional inheritance
      #
      # @return [String] The SEO title to use
      # @visibility public
      #
      def effective_seo_title
        return seo_title if seo_title.present?
        return title unless inherit_seo

        # Traverse up tree to find inherited value
        self_and_ancestors.reverse.find { |p| p.seo_title.present? }&.seo_title || title
      end

      #
      # Returns the effective SEO description for this page
      # With optional inheritance from parent pages
      #
      # @return [String, nil] The SEO description to use
      # @visibility public
      #
      def effective_seo_description
        return seo_description if seo_description.present?
        return nil unless inherit_seo

        self_and_ancestors.reverse.find { |p| p.seo_description.present? }&.seo_description
      end

      #
      # Returns the effective Open Graph title
      # Falls back to SEO title, then page title
      #
      # @return [String] The OG title to use
      # @visibility public
      #
      def effective_og_title
        og_title.presence || effective_seo_title
      end

      #
      # Returns the effective Open Graph description
      # Falls back to SEO description
      #
      # @return [String, nil] The OG description to use
      # @visibility public
      #
      def effective_og_description
        og_description.presence || effective_seo_description
      end

      #
      # Returns the effective canonical URL for this page
      # Falls back to the page's own URL if not explicitly set
      #
      # @return [String] The canonical URL to use
      # @visibility public
      #
      def effective_canonical_url
        canonical_url.presence || path
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

      #
      # Returns character counter states for SEO-related fields. Mirrors client
      # thresholds so we can assert limits without relying on system specs.
      #
      # @return [Hash<Symbol, Panda::CMS::Seo::CharacterCounter::Result>]
      # @visibility public
      #
      def seo_character_states
        {
          seo_title: character_state_for(seo_title, 70),
          seo_description: character_state_for(seo_description, 160),
          og_title: character_state_for(og_title, 60),
          og_description: character_state_for(og_description, 200)
        }
      end

      private

      def character_state_for(value, limit)
        Panda::CMS::Seo::CharacterCounter.evaluate(value, limit: limit)
      end

      def validate_unique_path_in_scope
        # Skip validation if path is not present (other validations will catch this)
        return if path.blank?

        # Find any other pages with the same path
        other_page = self.class.where(path: path).where.not(id: id).first

        return unless other_page
        # If there's another page with the same path, check if it has a different parent
        return unless other_page.parent_id == parent_id

        errors.add(:path, "has already been taken in this section")
      end

      #
      # After save callbacks
      #
      # @return nil
      # @visibility private
      #
      def handle_after_save
        generate_content_blocks
        update_existing_menu_items
        update_auto_menus
        create_redirect_if_path_changed
      end

      def generate_content_blocks
        template_block_ids = template.blocks.ids
        page_existing_block_ids = block_contents.map { |bc| bc.block.id }
        required_block_ids = template_block_ids - page_existing_block_ids

        return unless required_block_ids.count.positive?

        required_block_ids.each do |block_id|
          Panda::CMS::BlockContent.find_or_create_by!(page: self, panda_cms_block_id: block_id, content: "")
        end
      end

      #
      # Update text of existing menu items if the title differs
      #
      # @return nil
      # @todo Only run this if the page title has changed
      # @visibility private
      #
      def update_existing_menu_items
        menu_items.where.not(text: title).update_all(text: title)
      end

      def create_redirect_if_path_changed
        return unless saved_change_to_path?

        old_path = saved_changes["path"].first
        new_path = saved_changes["path"].last

        # Create a redirect from the old path to the new path
        Panda::CMS::Redirect.create!(
          origin_panda_cms_page_id: id,
          destination_panda_cms_page_id: id,
          status_code: 301,
          visits: 0,
          origin_path: old_path,
          destination_path: new_path
        )
      end

      def update_cached_last_updated_at
        # Will be set to updated_at automatically during save
        # Block content updates will call refresh_last_updated_at! separately
        # Only update if column exists (for backwards compatibility with older schemas)
        return unless self.class.column_names.include?("cached_last_updated_at")
        self.cached_last_updated_at = Time.current
      end
    end
  end
end
