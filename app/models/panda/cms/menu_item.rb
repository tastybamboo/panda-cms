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
      validates :page, presence: true, unless: -> { marked_for_destruction? || external_url.present? }
      validates :external_url, presence: true, unless: -> { marked_for_destruction? || page.present? }

      validate :validate_is_actual_link, unless: :marked_for_destruction?

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
      # Validate that the link is an actual link or a page
      #
      # @return nil
      # @visibility private
      def validate_is_actual_link
        if page.blank? && external_url.blank?
          errors.add(:page, "must be a valid page or external link, neither are set")
          errors.add(:external_url, "must be a valid page or external link, neither are set")
        end

        return unless page.present? && external_url.present?

        errors.add(:page, "must be a valid page or external link, both are set")
        errors.add(:external_url, "must be a valid page or external link, both are set")
      end
    end
  end
end
