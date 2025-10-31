# frozen_string_literal: true

module Panda
  module CMS
    # Grid layout component for creating column-based layouts
    # @param columns [Integer] Number of grid columns
    # @param spans [Array<Integer>] Array of column span values for each grid cell
    class GridComponent < Panda::Core::Base
      prop :columns, Integer, default: 1
      prop :spans, Array, default: -> { [1].freeze }

      def view_template
        div(class: "w-full grid #{grid_columns_class} min-h-20") do
          column_span_classes.each do |colspan|
            div(
              class: "border border-red-500 bg-red-50 #{colspan}",
              onDragOver: "parent.onDragOver(event);",
              onDrop: "parent.onDrop(event);"
            )
          end
        end
      end

      private

      def grid_columns_class
        "grid-cols-#{columns}"
      end

      def column_span_classes
        spans.map { |span| "col-span-#{span}" }
      end
    end
  end
end
