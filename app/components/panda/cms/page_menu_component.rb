# frozen_string_literal: true

module Panda
  module CMS
    # Page menu component for rendering hierarchical page navigation
    # @param page [Panda::CMS::Page] The current page
    # @param start_depth [Integer] The depth level to start the menu from
    # @param styles [Hash] CSS classes for styling menu elements
    # @param show_heading [Boolean] Whether to show the top-level heading
    class PageMenuComponent < Panda::Core::Base
      attr_reader :page, :start_depth, :styles, :show_heading

      def initialize(page:, start_depth:, styles: {}, show_heading: true, **attrs)
        @page = page
        @start_depth = start_depth
        @styles = styles.freeze
        @show_heading = show_heading
        super(**attrs)
      end

      def before_render
        return if @page.nil?

        @start_page = if @page.depth == @start_depth
          @page
        else
          @page.ancestors.find { |anc| anc.depth == @start_depth }
        end

        menu = @start_page&.page_menu
        return if menu.nil?

        # Fragment caching: Cache menu items for this page menu
        # Cache key includes menu's updated_at to auto-invalidate on changes
        cache_key = "panda_cms_page_menu/#{menu.id}/#{menu.updated_at.to_i}/items"

        cached_items = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          menu.menu_items.order(:lft).to_a
        end

        @menu_item = cached_items.first

        # Set default styles if not already set
        @styles[:indent_with] ||= "pl-2" if @styles
      end

      attr_reader :menu_item

      def should_render?
        @page&.path != "/" && @menu_item.present?
      end

      def heading_class
        if @menu_item.page == Panda::CMS::Current.page
          @styles[:current_page_active]
        else
          @styles[:current_page_inactive]
        end
      end

      def descendants_with_level
        return [] unless @menu_item

        Panda::CMS::MenuItem.includes(:page).each_with_level(@menu_item.descendants).select do |submenu_item, level|
          !should_skip_item?(submenu_item, level)
        end
      end

      private

      def should_skip_item?(submenu_item, level)
        # Skip if we're on the top menu item and level > 1
        return true if Panda::CMS::Current.page == @menu_item.page && level > 1

        # Skip if path contains parameter placeholder
        return true if submenu_item.page&.path&.include?(":")

        # Skip if page is nil or Current.page is nil
        return true if submenu_item&.page.nil? || Panda::CMS::Current.page.nil?

        # Skip if submenu page is deeper than current page and not an ancestor
        (submenu_item.page&.depth&.to_i&.> Panda::CMS::Current.page&.depth&.to_i) &&
          !Panda::CMS::Current.page&.in?(submenu_item.page.ancestors)
      end

      def menu_item_class(submenu_item)
        if submenu_item.page == Panda::CMS::Current.page
          @styles[:active]
        else
          @styles[:inactive]
        end
      end

      def menu_indent(submenu_item)
        helpers.menu_indent(submenu_item, indent_with: @styles[:indent_with])
      end
    end
  end
end
