# frozen_string_literal: true

require "awesome_nested_set"

module Panda
  module CMS
    class MenuItem < ApplicationRecord
      acts_as_nested_set scope: [:panda_cms_menu_id], counter_cache: :children_count

      self.implicit_order_column = "lft"
      self.table_name = "panda_cms_menu_items"

      belongs_to :menu, foreign_key: :panda_cms_menu_id, class_name: "Panda::CMS::Menu", inverse_of: :menu_items,
        touch: true
      belongs_to :page, foreign_key: :panda_cms_page_id, class_name: "Panda::CMS::Page", inverse_of: :menu_items,
        optional: true

      validates :text, presence: true, uniqueness: {scope: :panda_cms_menu_id, case_sensitive: false}

      validate :validate_page_or_external_url

      #
      # Returns the resolved link for the menu item.
      #
      # If the menu item is associated with a page, it returns the path of the page.
      # If the menu item is associated with an external URL, it returns the external URL.
      #
      # @return [String] Resolved link
      # @visibility public
      def resolved_link
        if page
          page.path
        elsif external_url
          external_url
        else
          ""
        end
      end

      private

      #
      # Validate that either page OR external URL is set, but not both or neither
      #
      # @return nil
      # @visibility private
      def validate_page_or_external_url
        if page.blank? && external_url.blank?
          errors.add(:base, "Please select either a page or enter an external URL")
        elsif page.present? && external_url.present?
          errors.add(:base, "Please select a page OR enter an external URL, not both")
        end
      end
    end
  end
end
