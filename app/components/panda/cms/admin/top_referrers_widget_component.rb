# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      # Dashboard widget for displaying top traffic referrers.
      #
      # Shows the top sources of traffic to the site from analytics data.
      #
      # @example Basic usage
      #   <%= render Panda::CMS::Admin::TopReferrersWidgetComponent.new %>
      #
      # @example With custom period and limit
      #   <%= render Panda::CMS::Admin::TopReferrersWidgetComponent.new(period: 7.days, limit: 10) %>
      #
      class TopReferrersWidgetComponent < BaseAnalyticsWidgetComponent
        # @param period [ActiveSupport::Duration] Time period for analytics
        # @param limit [Integer] Number of referrers to show
        def initialize(period: 30.days, limit: 10, **attrs)
          @limit = limit
          super(period: period, **attrs)
        end

        attr_reader :limit

        # Get top referrers
        # @return [Array<Hash>, nil]
        def top_referrers
          return nil unless provider

          @top_referrers ||= provider.top_referrers(limit: limit, period: period)
        rescue => e
          Rails.logger.error "[Panda CMS Analytics] Error fetching top referrers: #{e.message}"
          nil
        end
      end
    end
  end
end
