# frozen_string_literal: true

module Panda
  module CMS
    # Helper for rendering analytics tracking scripts from all configured providers.
    #
    # Include this helper in your layout's <head> to automatically inject tracking
    # scripts from any configured analytics providers (Google Analytics, Plausible,
    # Ahoy, etc.).
    #
    # @example In your application layout
    #   <head>
    #     <%= panda_analytics %>
    #   </head>
    #
    module AnalyticsHelper
      # Renders tracking scripts from all configured analytics providers.
      #
      # Iterates over every registered provider that supports tracking and is
      # fully configured, collecting their script tags into a single safe buffer.
      #
      # @param options [Hash] Options passed through to each provider's tracking_script
      # @return [ActiveSupport::SafeBuffer, nil] Combined script tags, or nil if none
      def panda_analytics(**options)
        scripts = Panda::CMS::Analytics.tracking_providers.filter_map do |provider|
          provider.tracking_script(**options)
        end
        return nil if scripts.empty?
        safe_join(scripts)
      end
    end
  end
end
