# frozen_string_literal: true

module Panda
  module CMS
    class MenuComponent < ViewComponent::Base
      #
      # Renders the menu item and its children
      #
      # @param [String] name The name of the menu
      # @param [String] current_path The current path of the request (request.path)
      # @param [Hash] styles
      #  The CSS classes to apply to the menu items, containing "default", "inactive" and "active" keys.
      #  The "default" key is applied to all menu items. "inactive" and "active" are set based on the
      #  current path.
      # @return [void]
      def initialize(name:, current_path: "", styles: {}, overrides: {}, render_page_menu: false, page_menu_styles: {})
        @menu = Panda::CMS::Menu.find_by(name: name)
        @menu_items = @menu.menu_items
        @menu_items = @menu_items.where("depth <= ?", @menu.depth) if @menu.depth
        @menu_items = @menu_items.order(:lft)
        @current_path = current_path.to_s
        @render_page_menu = render_page_menu

        @menu_items = @menu_items.order(:lft).map do |menu_item|
          if is_active?(menu_item)
            menu_item.define_singleton_method(:css_classes) { "#{styles[:default]} #{styles[:active]}" }
          else
            menu_item.define_singleton_method(:css_classes) { "#{styles[:default]} #{styles[:inactive]}" }
          end

          menu_item
        end

        # TODO: Surely don't need this but Current.page isn't working in the component
        return unless @render_page_menu

        @current_page = Panda::CMS::Page.find_by(path: @current_path)
        @page_menu_styles = page_menu_styles
      end

      def is_active?(menu_item)
        return true if @current_path == "/" && active_link?(menu_item.page.path, match: :exact)
        return true if menu_item.page.path != "/" && active_link?(menu_item.page.path, match: :starts_with)

        false
      end

      def active_link?(path, match: :starts_with)
        if match == :starts_with
          return @current_path.starts_with?(path)
        elsif match == :exact
          return (@current_path == path)
        end

        false
      end
    end
  end
end
