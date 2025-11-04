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

      private

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
        self.cached_last_updated_at = Time.current
      end
    end
  end
end
