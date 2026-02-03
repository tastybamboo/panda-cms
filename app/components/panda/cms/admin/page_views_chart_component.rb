# frozen_string_literal: true

require "chartkick"

module Panda
  module CMS
    module Admin
      # Dashboard widget for displaying page views over time as a chart.
      #
      # Shows a time series chart of page views from analytics data.
      #
      # @example Basic usage
      #   <%= render Panda::CMS::Admin::PageViewsChartComponent.new %>
      #
      # @example With custom period and interval
      #   <%= render Panda::CMS::Admin::PageViewsChartComponent.new(period: 7.days, interval: :daily) %>
      #
      class PageViewsChartComponent < BaseAnalyticsWidgetComponent
        include Chartkick::Helper

        # @param period [ActiveSupport::Duration] Time period for analytics
        # @param interval [Symbol] :daily, :weekly, or :monthly
        def initialize(period: 30.days, interval: :daily, **attrs)
          @interval = interval
          super(period: period, **attrs)
        end

        attr_reader :interval

        # Render the area chart
        # @return [String]
        def area_chart_html
          area_chart(chartkick_data,
            height: "300px",
            colors: ["#1a9597"],
            library: {
              plugins: {
                legend: {display: false}
              },
              scales: {
                y: {
                  beginAtZero: true,
                  ticks: {precision: 0}
                }
              }
            })
        end

        # Get page views over time
        # @return [Array<Hash>, nil]
        def page_views_data
          return nil unless provider

          @page_views_data ||= provider.page_views_over_time(period: period, interval: interval)
        rescue => e
          Rails.logger.error "[Panda CMS Analytics] Error fetching page views over time: #{e.message}"
          nil
        end

        # Convert data to Chartkick format
        # @return [Hash]
        def chartkick_data
          return {} unless page_views_data&.any?

          page_views_data.each_with_object({}) do |d, hash|
            hash[format_date(d[:date])] = d[:views]
          end
        end

        # Format date for display
        # @param date [Date]
        # @return [String]
        def format_date(date)
          case interval
          when :weekly
            date.strftime("%b %d")
          when :monthly
            date.strftime("%b %Y")
          else
            date.strftime("%b %d")
          end
        end
      end
    end
  end
end
