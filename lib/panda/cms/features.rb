# frozen_string_literal: true

module Panda
  module CMS
    # Lightweight feature flag registry so open-source core can gate functionality
    # that is only available when panda-cms-pro is installed.
    module Features
      Feature = Struct.new(:name, :provider, keyword_init: true)

      class MissingFeatureError < StandardError; end

      class << self
        def register(name, provider:)
          registry[name.to_sym] = Feature.new(name: name.to_sym, provider: provider)
        end

        def unregister(name)
          registry.delete(name.to_sym)
        end

        def reset!
          registry.clear
        end

        def enabled?(name)
          registry.key?(name.to_sym)
        end

        def require!(name)
          return if enabled?(name)

          raise MissingFeatureError,
            "The #{name} feature is only available with panda-cms-pro."
        end

        def provider_for(name)
          registry[name.to_sym]&.provider
        end

        def enabled_features
          registry.keys
        end

        private

        def registry
          @registry ||= {}
        end
      end
    end
  end
end
