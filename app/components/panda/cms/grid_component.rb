# frozen_string_literal: true

module Panda
  module CMS
    # Grid layout component for creating column-based layouts
    # @param columns [Integer] Number of grid columns
    # @param spans [Array<Integer>] Array of column span values for each grid cell
    class GridComponent < Panda::Core::Base
      attr_reader :columns, :spans

      def initialize(columns: 1, spans: [1], **attrs)
        @columns = columns
        @spans = spans
        super(**attrs)
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
