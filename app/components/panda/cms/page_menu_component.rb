# frozen_string_literal: true

module Panda
  module CMS
    # Page menu component for rendering hierarchical page navigation
    # @param page [Panda::CMS::Page] The current page
    # @param start_depth [Integer] The depth level to start the menu from
    # @param styles [Hash] CSS classes for styling menu elements
    # @param show_heading [Boolean] Whether to show the top-level heading
    # @param show_all_items [Boolean] When true, disables depth-based filtering so all descendants are shown
    class PageMenuComponent < Panda::Core::Base
      attr_reader :page, :start_depth, :styles, :show_heading, :show_all_items

      def initialize(page:, start_depth:, styles: {}, show_heading: true, show_all_items: false, **attrs)
        @page = page
        @start_depth = start_depth
        @styles = styles.freeze
        @show_heading = show_heading
        @show_all_items = show_all_items
        super(**attrs)
      end

      def before_render
        return if @page.nil?

        @start_page = if @page.depth == @start_depth
          @page
        else
          @page.ancestors.where(depth: @start_depth).first
        end

        @menu = @start_page&.page_menu
        return if @menu.nil?

        # Fragment caching: Cache menu items for this page menu
        # Cache key includes menu's updated_at to auto-invalidate on changes
        cache_key = "panda_cms_page_menu/#{@menu.id}/#{@menu.updated_at.to_i}/items"

        cached_items = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          @menu.menu_items.includes(:page).order(:lft).to_a
        end

        # Re-preload :page associations lost during Marshal deserialization from cache
        ActiveRecord::Associations::Preloader.new(records: cached_items, associations: :page).call if cached_items.present?

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
        items = collect_descendants
        items = promote_current_page(items) if @menu&.promote_active_item?
        items
      end

      private

      def collect_descendants
        return [] unless @menu_item

        items_with_levels = []
        Panda::CMS::MenuItem.each_with_level(@menu_item.descendants.includes(:page)) do |submenu_item, level|
          items_with_levels << [submenu_item, level]
        end

        items_with_levels.reject { |submenu_item, level| should_skip_item?(submenu_item, level) }
      end

      def promote_current_page(items)
        return items if items.empty?
        current_page = Panda::CMS::Current.page
        return items unless current_page

        current_item, other_items = items.partition { |submenu_item, _level| submenu_item.page == current_page }
        current_item + other_items
      end

      def should_skip_item?(submenu_item, level)
        # Skip if path contains parameter placeholder
        return true if submenu_item.page&.path&.include?(":")

        # Always skip items without an associated page
        return true if submenu_item&.page.nil?

        # When show_all_items is enabled, skip depth-based filtering
        # (used by mobile menus that need the full tree for JS-driven collapsing)
        return false if @show_all_items

        # From here on, we rely on Current.page being present for depth-based logic
        return true if Panda::CMS::Current.page.nil?

        # Skip if we're on the top menu item and level > 1
        return true if Panda::CMS::Current.page == @menu_item.page && level > 1

        # Skip if submenu page is deeper than current page and not an ancestor
        submenu_item.page.depth.to_i > Panda::CMS::Current.page.depth.to_i &&
          !submenu_item.page.is_descendant_of?(Panda::CMS::Current.page)
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
