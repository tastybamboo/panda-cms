# frozen_string_literal: true

module Panda
  module CMS
    class Menu < ApplicationRecord
      self.table_name = "panda_cms_menus"

      after_save :generate_auto_menu_items, if: -> { kind == "auto" }
      after_commit :clear_menu_cache

      attribute :pinned_page_ids, :json, default: []

      has_many :menu_items, lambda {
        order(lft: :asc)
      }, foreign_key: :panda_cms_menu_id, class_name: "Panda::CMS::MenuItem", inverse_of: :menu
      belongs_to :start_page, class_name: "Panda::CMS::Page", foreign_key: "start_page_id", inverse_of: :page_menu,
        optional: true

      accepts_nested_attributes_for :menu_items, reject_if: :all_blank, allow_destroy: true

      attribute :ordering, :string, default: "default"
      attribute :promote_active_item, :boolean, default: false

      validates :name, presence: true, uniqueness: {case_sensitive: false}
      validates :kind, presence: true, inclusion: {in: %w[static auto]}
      validates :ordering, inclusion: {in: %w[default alphabetical]}
      validate :validate_start_page

      def generate_auto_menu_items
        return false if kind != "auto"

        # NB: Transactions are not distributed across database connections
        transaction do
          menu_items.destroy_all
          menu_item_root = menu_items.create(text: start_page.title, panda_cms_page_id: start_page.id)
          generate_menu_items(parent_menu_item: menu_item_root, parent_page: start_page)
        end

        # Bump updated_at to bust fragment caches that depend on it.
        # Uses update_column to avoid re-triggering after_save callbacks.
        update_column(:updated_at, Time.current)
        clear_menu_cache
      end

      def page_pinned?(page_id)
        pinned_page_ids.include?(page_id.to_s)
      end

      def pin_page(page_id)
        id_str = page_id.to_s
        return if pinned_page_ids.include?(id_str)
        self.pinned_page_ids = pinned_page_ids + [id_str]
      end

      def unpin_page(page_id)
        self.pinned_page_ids = pinned_page_ids - [page_id.to_s]
      end

      private

      def generate_menu_items(parent_menu_item:, parent_page:)
        children = parent_page.children.where(status: :published)
        children = order_pages(children)

        children.each do |page|
          menu_item = menu_items.create(text: page.title, panda_cms_page_id: page.id, parent: parent_menu_item)
          generate_menu_items(parent_menu_item: menu_item, parent_page: page) if page.children
        end
      end

      def order_pages(pages)
        ordered = case ordering
        when "alphabetical"
          pages.reorder(:title)
        else
          pages # Default uses nested set order (lft)
        end

        return ordered if pinned_page_ids.empty?

        all_pages = ordered.to_a
        pin_ids = pinned_page_ids.map(&:to_s)
        pin_positions = {}
        pin_ids.each_with_index { |id, idx| pin_positions[id] = idx }
        pinned, unpinned = all_pages.partition { |p| pin_positions.key?(p.id.to_s) }
        pinned.sort_by! { |p| pin_positions[p.id.to_s] }
        pinned + unpinned
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
