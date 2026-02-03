# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      # Dashboard widget for displaying recently edited pages.
      #
      # Shows the most recently updated pages in the CMS.
      #
      # @example Basic usage
      #   <%= render Panda::CMS::Admin::RecentPagesWidgetComponent.new %>
      #
      # @example With custom limit
      #   <%= render Panda::CMS::Admin::RecentPagesWidgetComponent.new(limit: 5) %>
      #
      class RecentPagesWidgetComponent < Panda::Core::Base
        include Panda::CMS::Engine.routes.url_helpers

        # @param limit [Integer] Number of pages to show
        def initialize(limit: 10, **attrs)
          @limit = limit
          super(**attrs)
        end

        attr_reader :limit

        def default_attrs
          {class: "bg-white rounded-2xl border border-gray-200 p-6"}
        end

        # Get recently updated pages
        # @return [ActiveRecord::Relation]
        def recent_pages
          @recent_pages ||= Panda::CMS::Page
            .order(updated_at: :desc)
            .limit(limit)
        end

        # Format time ago
        # @param time [Time]
        # @return [String]
        def time_ago(time)
          distance_of_time_in_words(time, Time.current, include_seconds: false) + " ago"
        end

        # Get page status badge color
        # @param page [Panda::CMS::Page]
        # @return [String]
        def status_color(page)
          case page.status
          when "active" then "bg-green-100 text-green-800"
          when "draft" then "bg-yellow-100 text-yellow-800"
          when "archived" then "bg-gray-100 text-gray-800"
          else "bg-gray-100 text-gray-800"
          end
        end
      end
    end
  end
end
