# frozen_string_literal: true

module Panda
  module CMS
    module Analytics
      # Local analytics provider using the built-in Visit model.
      #
      # This provider uses data from Panda::CMS::Visit to display analytics
      # without requiring external services.
      #
      # @example Usage
      #   provider = Panda::CMS::Analytics::LocalProvider.new
      #   provider.page_views(period: 7.days)
      #   provider.top_pages(limit: 5)
      #
      class LocalProvider < Provider
        def configured?
          true # Always available
        end

        def page_views(period: 30.days)
          scope = Panda::CMS::Visit.all
          scope = scope.where("visited_at >= ?", period.ago) if period
          scope.count
        end

        def unique_visitors(period: 30.days)
          scope = Panda::CMS::Visit.all
          scope = scope.where("visited_at >= ?", period.ago) if period
          # Use ip_address as a proxy for unique visitors
          scope.distinct.count(:ip_address)
        end

        def top_pages(limit: 10, period: 30.days)
          results = Panda::CMS::Visit.popular_pages(limit: limit, period: period)

          results.map do |result|
            {
              path: result.path,
              title: result.title || result.path,
              views: result.visit_count
            }
          end
        end

        def page_views_over_time(period: 30.days, interval: :daily)
          scope = Panda::CMS::Visit.where("visited_at >= ?", period.ago)

          case interval
          when :daily
            scope
              .group(Arel.sql("DATE(visited_at)"))
              .order(Arel.sql("DATE(visited_at)"))
              .count
              .map { |date, count| {date: date, views: count} }
          when :weekly
            scope
              .group(Arel.sql("DATE_TRUNC('week', visited_at)"))
              .order(Arel.sql("DATE_TRUNC('week', visited_at)"))
              .count
              .map { |date, count| {date: date.to_date, views: count} }
          when :monthly
            scope
              .group(Arel.sql("DATE_TRUNC('month', visited_at)"))
              .order(Arel.sql("DATE_TRUNC('month', visited_at)"))
              .count
              .map { |date, count| {date: date.to_date, views: count} }
          end
        end

        def top_referrers(limit: 10, period: 30.days)
          scope = Panda::CMS::Visit.where.not(referrer: [nil, ""])
          scope = scope.where("visited_at >= ?", period.ago) if period

          scope
            .group(:referrer)
            .order("count_all DESC")
            .limit(limit)
            .count
            .map { |referrer, count| {source: referrer, visits: count} }
        end

        def name
          "Local Analytics"
        end
      end
    end
  end
end
