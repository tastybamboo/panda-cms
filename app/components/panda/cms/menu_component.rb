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
    class MenuComponent < Panda::Core::Base
      attr_reader :name, :current_path, :styles, :overrides, :render_page_menu, :page_menu_styles

      def initialize(name:, current_path: "", styles: {}, overrides: {}, render_page_menu: false, page_menu_styles: {}, **attrs)
        @name = name
        @current_path = current_path
        @styles = styles
        @overrides = overrides
        @render_page_menu = render_page_menu
        @page_menu_styles = page_menu_styles
        super(**attrs)
      end

      def call
        return "".html_safe unless menu_exists?
        "<!-- Menu: #{@name} -->".html_safe
      end

      private

      def menu_exists?
        @name.present?
      end
    end
  end
end
