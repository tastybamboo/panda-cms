# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      # Dashboard widget for displaying analytics summary.
      #
      # This component displays key analytics metrics from the configured provider.
      # Falls back gracefully when no analytics data is available.
      #
      # @example Basic usage
      #   <%= render Panda::CMS::Admin::AnalyticsWidgetComponent.new %>
      #
      # @example With custom period
      #   <%= render Panda::CMS::Admin::AnalyticsWidgetComponent.new(period: 7.days) %>
      #
      class AnalyticsWidgetComponent < Panda::Core::Base
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

        # Get summary statistics
        # @return [Hash, nil]
        def summary
          return nil unless provider

          @summary ||= provider.summary(period: period)
        rescue => e
          Rails.logger.error "[Panda CMS Analytics] Error fetching summary: #{e.message}"
          nil
        end

        # Get top pages
        # @return [Array<Hash>, nil]
        def top_pages
          return nil unless provider

          @top_pages ||= provider.top_pages(limit: 5, period: period)
        rescue => e
          Rails.logger.error "[Panda CMS Analytics] Error fetching top pages: #{e.message}"
          nil
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
