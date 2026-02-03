# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      # Base component for analytics dashboard widgets.
      #
      # Provides common functionality for analytics widgets including:
      # - Analytics provider access and availability checking
      # - Number and period label formatting
      # - Consistent default styling
      #
      # Child components should override #period if they need custom periods.
      #
      # @example Creating a custom analytics widget
      #   class MyAnalyticsWidget < BaseAnalyticsWidgetComponent
      #     def my_custom_data
      #       return nil unless provider
      #       provider.my_custom_method(period: period)
      #     end
      #   end
      #
      class BaseAnalyticsWidgetComponent < Panda::Core::Base
        # @param period [ActiveSupport::Duration] Time period for analytics
        def initialize(period: 30.days, **attrs)
          @period = period
          super(**attrs)
        end

        attr_reader :period

        def default_attrs
          {class: "bg-white rounded-2xl border border-gray-200 p-6"}
        end

        # Check if analytics is available and configured
        # @return [Boolean]
        def analytics_available?
          Panda::CMS::Analytics.available?
        rescue
          false
        end

        # Get the analytics provider
        # @return [Panda::CMS::Analytics::Provider, nil]
        def provider
          return nil unless analytics_available?

          Panda::CMS::Analytics.provider
        end

        # Format number with thousands separator
        # @param number [Integer]
        # @return [String]
        def format_number(number)
          return "N/A" unless number

          number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
        end

        # Human-readable period label
        # @return [String]
        def period_label
          case period
          when 1.day then "Today"
          when 7.days then "Last 7 days"
          when 30.days then "Last 30 days"
          when 90.days then "Last 90 days"
          when 1.year then "Last year"
          else
            "Last #{(period / 1.day).to_i} days"
          end
        end
      end
    end
  end
end
