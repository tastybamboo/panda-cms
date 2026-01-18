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
        @styles = styles
        @show_heading = show_heading
        super(**attrs)
      end

      def call
        return "" unless should_render?
        "<!-- Page Menu -->"
      end

      private

      def should_render?
        @page.present?
      end
    end
  end
end
