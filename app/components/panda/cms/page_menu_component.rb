# frozen_string_literal: true

module Panda
  module CMS
    class PageMenuComponent < ViewComponent::Base
      attr_accessor :page, :menu_item, :styles

      def initialize(page:, start_depth:, styles: {}, show_heading: true)
        @page = page

        return if @page.nil?

        start_page = if @page.depth == start_depth
          @page
        else
          @page.ancestors.find { |anc| anc.depth == start_depth }
        end

        menu = start_page&.page_menu
        return if menu.nil?

        @menu_item = menu.menu_items.order(:lft)&.first

        @show_heading = show_heading

        # Set some default styles for sanity
        @styles = styles
        @styles[:indent_with] ||= "pl-2"
      end

      def render?
        @page&.path != "/" && @menu_item.present?
      end
    end
  end
end
