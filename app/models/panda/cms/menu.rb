# frozen_string_literal: true

module Panda
  module CMS
    class Menu < ApplicationRecord
      self.table_name = "panda_cms_menus"

      after_save :generate_auto_menu_items, if: :should_regenerate_menu_items?
      after_commit :clear_menu_cache

      has_many :menu_items, lambda {
        order(lft: :asc)
      }, foreign_key: :panda_cms_menu_id, class_name: "Panda::CMS::MenuItem", inverse_of: :menu
      belongs_to :start_page, class_name: "Panda::CMS::Page", foreign_key: "start_page_id", inverse_of: :page_menu,
        optional: true

      accepts_nested_attributes_for :menu_items, reject_if: :all_blank, allow_destroy: true

      validates :name, presence: true, uniqueness: {case_sensitive: false}
      validates :kind, presence: true, inclusion: {in: %w[static auto]}
      validate :validate_start_page

      def generate_auto_menu_items
        return false if kind != "auto"
        return unless start_page # Can't generate without a start page

        transaction do
          # Destroy all existing menu items using unscoped to avoid caching issues
          Panda::CMS::MenuItem.unscoped.where(panda_cms_menu_id: id).destroy_all

          # Create new menu structure
          menu_item_root = menu_items.create!(text: start_page.title, panda_cms_page_id: start_page.id)
          generate_menu_items(parent_menu_item: menu_item_root, parent_page: start_page, current_depth: 0)
        end
      end

      private

      def should_regenerate_menu_items?
        return false unless kind == "auto"
        # Only regenerate if relevant attributes changed or it's a new record
        saved_change_to_kind? || saved_change_to_start_page_id? || saved_change_to_depth?
      end

      def generate_menu_items(parent_menu_item:, parent_page:, current_depth:)
        # Stop recursing if we've reached the depth limit
        # depth attribute limits how deep to go (nil means unlimited)
        return if depth.present? && current_depth >= depth

        parent_page.children.where(status: [:active]).each do |page|
          menu_item = menu_items.create(text: page.title, panda_cms_page_id: page.id, parent: parent_menu_item)
          generate_menu_items(parent_menu_item: menu_item, parent_page: page, current_depth: current_depth + 1) if page.children.any?
        end
      end

      #
      # Validate that the start page is set if the menu is of kind auto
      #
      # @return nil
      # @visibility private
      #
      def validate_start_page
        return unless kind == "auto" && start_page.nil?

        errors.add(:start_page, "can't be blank")
      end

      #
      # Clear fragment cache when menu is updated
      # This ensures menu changes appear immediately on the front-end
      #
      # @return nil
      # @visibility private
      #
      def clear_menu_cache
        Rails.cache.delete("panda_cms_menu/#{name}/#{id}")
      end
    end
  end
end
