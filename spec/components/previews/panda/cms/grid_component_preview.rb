# frozen_string_literal: true

module Panda
  module CMS
    # @label Grid
    class GridComponentPreview < Lookbook::Preview
      # Basic 2-column grid
      # @label Two Columns
      def two_columns
        render Panda::CMS::GridComponent.new(columns: 2, spans: [1, 1]) do |component|
          component.with_content do
            <<~HTML.html_safe
              <div class="bg-blue-100 p-4 rounded">Column 1</div>
              <div class="bg-green-100 p-4 rounded">Column 2</div>
            HTML
          end
        end
      end

      # 3-column grid
      # @label Three Columns
      def three_columns
        render Panda::CMS::GridComponent.new(columns: 3, spans: [1, 1, 1]) do |component|
          component.with_content do
            <<~HTML.html_safe
              <div class="bg-blue-100 p-4 rounded">Column 1</div>
              <div class="bg-green-100 p-4 rounded">Column 2</div>
              <div class="bg-purple-100 p-4 rounded">Column 3</div>
            HTML
          end
        end
      end

      # Grid with different column spans
      # @label Custom Spans
      def custom_spans
        render Panda::CMS::GridComponent.new(columns: 3, spans: [2, 1]) do |component|
          component.with_content do
            <<~HTML.html_safe
              <div class="bg-blue-100 p-4 rounded">Wide column (spans 2)</div>
              <div class="bg-green-100 p-4 rounded">Narrow column (spans 1)</div>
            HTML
          end
        end
      end
    end
  end
end
