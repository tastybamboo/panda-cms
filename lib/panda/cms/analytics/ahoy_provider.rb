# frozen_string_literal: true

module Panda
  module CMS
    module Analytics
      # Analytics provider using Ahoy for visit and event tracking.
      #
      # When the ahoy_matey gem is installed, this provider queries Ahoy::Visit
      # and Ahoy::Event for dashboard analytics data. It can also optionally
      # inject the ahoy.js tracking script on public pages.
      #
      # This provider is auto-registered when Ahoy is detected and replaces
      # LocalProvider as the default data source.
      #
      # @example Enable frontend tracking via admin settings
      #   # In Panda::CMS.config.analytics[:ahoy]:
      #   { enabled: true, tracking_enabled: true }
      #
      class AhoyProvider < Provider
        def self.slug
          :ahoy
        end

        def self.display_name
          "Ahoy"
        end

        def self.icon
          "fa-solid fa-anchor"
        end

        def self.has_settings_page?
          false
        end

        def configured?
          defined?(::Ahoy::Visit) ? true : false
        end

        # --- Frontend tracking ---

        def supports_tracking?
          true
        end

        def tracking_configured?
          return false unless configured?
          config[:enabled] == true && config[:tracking_enabled] == true
        end

        def tracking_script(**options)
          return nil unless tracking_configured?

          # rubocop:disable Rails/OutputSafety
          <<~HTML.html_safe
            <!-- Ahoy.js -->
            <script src="/ahoy.js"></script>
          HTML
          # rubocop:enable Rails/OutputSafety
        end

        # --- Data API ---

        INTERVAL_TRUNCATIONS = {weekly: "week", monthly: "month", daily: "day"}.freeze

        def page_views(period: 30.days)
          return 0 unless configured?
          scope = ::Ahoy::Visit.where("started_at >= ?", period.ago)
          scope.sum { |v| v.respond_to?(:events) ? v.events.count : 1 }
        rescue
          fallback_provider.page_views(period: period)
        end

        def unique_visitors(period: 30.days)
          return 0 unless configured?
          ::Ahoy::Visit.where("started_at >= ?", period.ago).distinct.count(:visitor_token)
        rescue
          fallback_provider.unique_visitors(period: period)
        end

        def top_pages(limit: 10, period: 30.days)
          return [] unless configured?
          return fallback_provider.top_pages(limit: limit, period: period) unless defined?(::Ahoy::Event)

          ::Ahoy::Event
            .where(name: "$view")
            .where("time >= ?", period.ago)
            .group("properties->>'url'")
            .order(Arel.sql("count(*) DESC"))
            .limit(limit)
            .count
            .map { |url, count| {path: url, title: url, views: count} }
        rescue
          fallback_provider.top_pages(limit: limit, period: period)
        end

        def page_views_over_time(period: 30.days, interval: :daily)
          return [] unless configured?

          trunc = INTERVAL_TRUNCATIONS.fetch(interval, "day")

          ::Ahoy::Visit
            .where("started_at >= ?", period.ago)
            .group(Arel.sql("DATE_TRUNC('#{trunc}', started_at)"))
            .order(Arel.sql("DATE_TRUNC('#{trunc}', started_at)"))
            .count
            .map { |date, count| {date: date.to_date, views: count} }
        rescue
          fallback_provider.page_views_over_time(period: period, interval: interval)
        end

        def top_referrers(limit: 10, period: 30.days)
          return [] unless configured?

          ::Ahoy::Visit
            .where("started_at >= ?", period.ago)
            .where.not(referring_domain: [nil, ""])
            .group(:referring_domain)
            .order(Arel.sql("count(*) DESC"))
            .limit(limit)
            .count
            .map { |domain, count| {source: domain, visits: count} }
        rescue
          fallback_provider.top_referrers(limit: limit, period: period)
        end

        private

        def fallback_provider
          @fallback_provider ||= LocalProvider.new
        end
      end
    end
  end
end
