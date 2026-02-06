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
        # Shared period mapping: query param code → [label, duration]
        PERIODS = {
          "1h" => ["Last hour", 1.hour],
          "24h" => ["Last 24 hours", 1.day],
          "7d" => ["Last 7 days", 7.days],
          "30d" => ["Last 30 days", 30.days],
          "90d" => ["Last 90 days", 90.days]
        }.freeze

        DEFAULT_PERIOD_CODE = "30d"
        DEFAULT_PERIOD_DURATION = PERIODS[DEFAULT_PERIOD_CODE].last

        # Resolve a query param code to a duration
        # @param code [String, nil]
        # @return [ActiveSupport::Duration]
        def self.duration_for(code)
          PERIODS.dig(code, 1) || DEFAULT_PERIOD_DURATION
        end

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
          PERIODS.each_value do |label, duration|
            return label if duration == period
          end
          "Last #{(period / 1.day).to_i} days"
        end

        # Available period options for the dropdown
        # @return [Array<[String, String]>] label/value pairs
        def period_options
          PERIODS.map { |code, (label, _duration)| [label, code] }
        end

        # Current period as a query param value
        # @return [String]
        def period_value
          PERIODS.find { |_code, (_label, duration)| duration == period }&.first || DEFAULT_PERIOD_CODE
        end
      end
    end
  end
end
