# frozen_string_literal: true

module Panda
  module CMS
    # Menu component for rendering navigational menus
    # @param name [String] The name of the menu to render
    # @param current_path [String] The current request path for highlighting active items
    # @param styles [Hash] CSS classes for menu items (default, active, inactive)
    # @param overrides [Hash] Menu item overrides (currently unused)
    # @param render_page_menu [Boolean] Whether to render sub-page menus
    # @param page_menu_styles [Hash] Styles for the page menu component
    class MenuComponent < Panda::Core::Base
      prop :name, String
      prop :current_path, String, default: ""
      prop :styles, Hash, default: -> { {}.freeze }
      prop :overrides, Hash, default: -> { {}.freeze }
      prop :render_page_menu, _Boolean, default: false
      prop :page_menu_styles, Hash, default: -> { {}.freeze }

      def view_template
        return unless @menu

        @processed_menu_items.each do |menu_item|
          a(href: menu_item.resolved_link, class: menu_item.css_classes) { menu_item.text }

          if @render_page_menu && menu_item.page
            render Panda::CMS::PageMenuComponent.new(
              page: menu_item.page,
              start_depth: 1,
              styles: @page_menu_styles,
              show_heading: false
            )
          end
        end
      end

      def before_template
        load_menu_items
      end

      private

      def load_menu_items
        @menu = Panda::CMS::Menu.find_by(name: @name)
        return unless @menu

        # Fragment caching: Cache menu_items query results
        # Cache key includes menu's updated_at to auto-invalidate on changes
        cache_key = "panda_cms_menu/#{@menu.name}/#{@menu.id}/#{@menu.updated_at.to_i}/items"

        menu_items = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          items = @menu.menu_items
          items = items.where("depth <= ?", @menu.depth) if @menu.depth
          items.order(:lft).to_a  # Convert to array for caching
        end

        @processed_menu_items = menu_items.map do |menu_item|
          add_css_classes_to_item(menu_item)
          menu_item
        end

        # Load current page for page menu rendering
        if @render_page_menu
          @current_page = Panda::CMS::Page.find_by(path: @current_path)
        end
      end

      def add_css_classes_to_item(menu_item)
        css_class = if is_active?(menu_item)
          "#{@styles[:default]} #{@styles[:active]}"
        else
          "#{@styles[:default]} #{@styles[:inactive]}"
        end

        menu_item.define_singleton_method(:css_classes) { css_class }
      end

      def is_active?(menu_item)
        return true if @current_path == "/" && active_link?(menu_item.page.path, match: :exact)
        return true if menu_item.page.path != "/" && active_link?(menu_item.page.path, match: :starts_with)

        false
      end

      def active_link?(path, match: :starts_with)
        case match
        when :starts_with
          @current_path.starts_with?(path)
        when :exact
          @current_path == path
        else
          false
        end
      end
    end
  end
end
