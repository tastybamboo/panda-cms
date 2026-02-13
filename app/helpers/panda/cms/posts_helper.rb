# frozen_string_literal: true

module Panda
  module CMS
    module PostsHelper
      def display_post_path(post)
        # Unescape the path for display purposes
        CGI.unescape(post.slug)
      end

      def posts_months_menu
        Rails.cache.fetch("panda_cms_posts_months_menu", expires_in: 1.hour) do
          Panda::CMS::Post
            .where(status: :published)
            .select(
              Arel.sql("DATE_TRUNC('month', published_at) as month"),
              Arel.sql("COUNT(*) as post_count")
            )
            .group(Arel.sql("DATE_TRUNC('month', published_at)"))
            .order(Arel.sql("DATE_TRUNC('month', published_at) DESC"))
            .map do |result|
              date = result.month
              {
                year: date.strftime("%Y"),
                month: date.strftime("%m"),
                month_name: "#{date.strftime("%B")} #{date.year}",
                post_count: result.post_count
              }
            end
        end
      end
    end
  end
end
