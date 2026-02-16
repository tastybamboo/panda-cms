# frozen_string_literal: true

module Panda
  module CMS
    # Menu component for rendering navigational menus
    # @param name [String] The name of the menu to render
    # @param current_path [String] The current request path for highlighting active items
    # @param styles [Hash] CSS classes for menu items (default, active, inactive)
    # @param overrides [Hash] Menu item overrides - supports :hidden_items array to hide specific menu items by text
    # @param render_page_menu [Boolean] Whether to render sub-page menus
    # @param page_menu_styles [Hash] Styles for the page menu component
    # @param page_menu_show_all_items [Boolean] When true, page menus show all descendants (disables depth filtering)
    class MenuComponent < Panda::Core::Base
      attr_reader :name, :current_path, :styles, :overrides, :render_page_menu, :page_menu_styles, :page_menu_show_all_items

      def initialize(name:, current_path: "", styles: {}, overrides: {}, render_page_menu: false, page_menu_styles: {}, page_menu_show_all_items: false, **attrs)
        @name = name
        @current_path = current_path
        @styles = styles.freeze
        @overrides = overrides.freeze
        @render_page_menu = render_page_menu
        @page_menu_styles = page_menu_styles.freeze
        @page_menu_show_all_items = page_menu_show_all_items
        super(**attrs)
      end

      def before_render
        load_menu_items
      end

      def processed_menu_items
        @processed_menu_items || []
      end

      private

      def load_menu_items
        @menu = Panda::CMS::Menu.find_by(name: @name)
        return unless @menu

        # Fragment caching: Cache menu_items query results
        # Cache key includes menu's updated_at to auto-invalidate on changes
        cache_key = "panda_cms_menu/#{@menu.name}/#{@menu.id}/#{@menu.updated_at.to_i}/items"

        menu_items = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          items = @menu.menu_items.includes(:page)
          items = items.where("depth <= ?", @menu.depth) if @menu.depth
          items.order(:lft).to_a # Convert to array for caching
        end

        # Re-preload :page associations lost during Marshal deserialization from cache
        ActiveRecord::Associations::Preloader.new(records: menu_items, associations: :page).call

        # Filter menu items based on overrides
        filtered_menu_items = if @overrides[:hidden_items].present?
          menu_items.reject { |item| @overrides[:hidden_items].include?(item.text) }
        else
          menu_items
        end

        @processed_menu_items = filtered_menu_items.map do |menu_item|
          add_css_classes_to_item(menu_item)
          menu_item
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
        link_path = menu_item.resolved_link
        return false if link_path.blank?

        return true if @current_path == "/" && active_link?(link_path, match: :exact)
        return true if link_path != "/" && active_link?(link_path, match: :starts_with)

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
