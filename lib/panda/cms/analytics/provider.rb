# frozen_string_literal: true

module Panda
  module CMS
    module Analytics
      # Base class for analytics providers.
      #
      # Implement this class to create custom analytics integrations.
      # Each provider must implement the required methods to fetch analytics data.
      #
      # @example Creating a custom provider
      #   class MyAnalyticsProvider < Panda::CMS::Analytics::Provider
      #     def page_views(period: 30.days)
      #       # Fetch from your analytics service
      #     end
      #
      #     def top_pages(limit: 10, period: 30.days)
      #       # Fetch from your analytics service
      #     end
      #   end
      #
      # @example Registering a provider
      #   Panda::CMS::Analytics.register_provider(:my_analytics, MyAnalyticsProvider)
      #
      class Provider
        # @return [Hash] Configuration options for this provider
        attr_reader :config

        # Initialize the provider with configuration
        # @param config [Hash] Configuration options
        def initialize(config = {})
          @config = config
        end

        # Check if the provider is properly configured and ready to use
        # @return [Boolean]
        def configured?
          raise NotImplementedError, "Subclass must implement #configured?"
        end

        # Get total page views for a period
        # @param period [ActiveSupport::Duration] Time period (e.g., 30.days)
        # @return [Integer] Total page views
        def page_views(period: 30.days)
          raise NotImplementedError, "Subclass must implement #page_views"
        end

        # Get unique visitors for a period
        # @param period [ActiveSupport::Duration] Time period
        # @return [Integer] Unique visitors
        def unique_visitors(period: 30.days)
          raise NotImplementedError, "Subclass must implement #unique_visitors"
        end

        # Get top pages by views
        # @param limit [Integer] Number of pages to return
        # @param period [ActiveSupport::Duration] Time period
        # @return [Array<Hash>] Array of {path:, title:, views:} hashes
        def top_pages(limit: 10, period: 30.days)
          raise NotImplementedError, "Subclass must implement #top_pages"
        end

        # Get page views over time (for charts)
        # @param period [ActiveSupport::Duration] Time period
        # @param interval [Symbol] :daily, :weekly, or :monthly
        # @return [Array<Hash>] Array of {date:, views:} hashes
        def page_views_over_time(period: 30.days, interval: :daily)
          raise NotImplementedError, "Subclass must implement #page_views_over_time"
        end

        # Get top referrers
        # @param limit [Integer] Number of referrers to return
        # @param period [ActiveSupport::Duration] Time period
        # @return [Array<Hash>] Array of {source:, visits:} hashes
        def top_referrers(limit: 10, period: 30.days)
          raise NotImplementedError, "Subclass must implement #top_referrers"
        end

        # Get summary statistics for the dashboard
        # @param period [ActiveSupport::Duration] Time period
        # @return [Hash] Summary stats {page_views:, unique_visitors:, avg_time_on_site:, bounce_rate:}
        def summary(period: 30.days)
          {
            page_views: page_views(period: period),
            unique_visitors: unique_visitors(period: period),
            avg_time_on_site: nil,
            bounce_rate: nil
          }
        end

        # Human-readable name for this provider
        # @return [String]
        def name
          self.class.name.demodulize.gsub("Provider", "")
        end
      end
    end
  end
end
