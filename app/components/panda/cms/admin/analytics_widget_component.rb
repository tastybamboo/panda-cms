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
      class AnalyticsWidgetComponent < BaseAnalyticsWidgetComponent
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
      end
    end
  end
end
