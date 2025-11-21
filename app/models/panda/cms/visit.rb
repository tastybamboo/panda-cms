# frozen_string_literal: true

module Panda
  module CMS
    class Visit < ApplicationRecord
      belongs_to :page, class_name: "Panda::CMS::Page", foreign_key: :page_id, optional: true
      belongs_to :user, class_name: "Panda::Core::User", foreign_key: :user_id, optional: true
      belongs_to :redirect, class_name: "Panda::CMS::Redirect", foreign_key: :redirect_id, optional: true

      # Returns the most popular pages by visit count
      # @param limit [Integer] Number of pages to return (default: 10)
      # @param period [ActiveSupport::Duration] Time period to consider (default: all time)
      # @return [Array<Hash>] Array of hashes with page and visit_count
      def self.popular_pages(limit: 10, period: nil)
        scope = joins(:page).where.not(page_id: nil)
        scope = scope.where("visited_at >= ?", period.ago) if period

        scope
          .group("panda_cms_pages.id", "panda_cms_pages.title", "panda_cms_pages.path")
          .select("panda_cms_pages.id, panda_cms_pages.title, panda_cms_pages.path, COUNT(*) as visit_count")
          .order("visit_count DESC")
          .limit(limit)
      end
    end
  end
end
