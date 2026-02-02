# frozen_string_literal: true

require_relative "analytics/provider"
require_relative "analytics/local_provider"
require_relative "analytics/ahoy_provider"

module Panda
  module CMS
    # Analytics integration module for Panda CMS.
    #
    # This module provides a pluggable system for integrating analytics providers.
    # Use the built-in LocalProvider for simple analytics, or configure external
    # providers like Google Analytics (via panda-cms-pro).
    #
    # @example Configure analytics
    #   Panda::CMS::Analytics.configure do |config|
    #     config.provider = :google_analytics
    #     config.credentials = {
    #       property_id: "GA4-XXXXXX"
    #     }
    #   end
    #
    # @example Get the current provider
    #   provider = Panda::CMS::Analytics.provider
    #   provider.page_views(period: 7.days)
    #
    module Analytics
      class << self
        # @return [Symbol] The current provider name
        attr_accessor :current_provider_name

        # @return [Hash] Provider-specific configuration
        attr_accessor :provider_config

        # Registry of available providers
        # @return [Hash<Symbol, Class>]
        def providers
          @providers ||= {
            local: LocalProvider
          }
        end

        # Register a new analytics provider
        # @param name [Symbol] Provider identifier
        # @param klass [Class] Provider class (must inherit from Provider)
        def register_provider(name, klass)
          unless klass < Provider
            raise ArgumentError, "Provider class must inherit from Panda::CMS::Analytics::Provider"
          end

          providers[name.to_sym] = klass
        end

        # Configure analytics settings
        # @yield [config] Configuration block
        def configure
          yield self if block_given?
        end

        # Get the currently configured provider instance
        # @return [Provider]
        def provider
          @provider ||= build_provider
        end

        # Reset the provider instance (useful after configuration changes)
        def reset!
          @provider = nil
          @tracking_providers = nil
        end

        # Check if analytics is available
        # @return [Boolean]
        def available?
          provider.configured?
        rescue
          false
        end

        # Returns all registered provider instances where tracking is supported and configured
        # @return [Array<Provider>]
        def tracking_providers
          @tracking_providers ||= build_tracking_providers
        end

        # Returns all provider classes that have a settings page
        # @return [Array<Class>]
        def settings_providers
          providers.values.select(&:has_settings_page?)
        end

        private

        def build_provider
          provider_name = current_provider_name || :local
          provider_class = providers[provider_name]

          unless provider_class
            Rails.logger.warn "[Panda CMS Analytics] Unknown provider '#{provider_name}', falling back to local"
            provider_class = LocalProvider
          end

          provider_class.new(provider_config || {})
        end

        def build_tracking_providers
          providers.filter_map do |name, klass|
            config = provider_configs_for(name)
            instance = klass.new(config)
            instance if instance.supports_tracking? && instance.tracking_configured?
          end
        end

        def provider_configs_for(name)
          analytics_config = Panda::CMS.config.respond_to?(:analytics) && Panda::CMS.config.analytics
          return {} unless analytics_config.is_a?(Hash)
          analytics_config[name] || {}
        end
      end
    end
  end
end
