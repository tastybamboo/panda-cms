# frozen_string_literal: true

require "rubygems"
require "panda/core"
require "panda/core/engine"
require "panda/editor"
require "panda/editor/engine"
require "panda/cms/railtie"

require "invisible_captcha"

require_relative "engine/autoload_config"
require_relative "engine/asset_config"
require_relative "engine/route_config"
require_relative "engine/core_config"
require_relative "engine/helper_config"
require_relative "engine/backtrace_config"

module Panda
  module CMS
    class Engine < ::Rails::Engine
      isolate_namespace Panda::CMS

      include Panda::Core::Shared::InflectionsConfig
      include Panda::Core::Shared::GeneratorConfig

      include AutoloadConfig
      include AssetConfig
      include RouteConfig
      include CoreConfig
      include HelperConfig
      include BacktraceConfig

      initializer "panda_cms.importmap", before: "importmap" do |app|
        Panda::CMS.importmap = Importmap::Map.new.tap do |map|
          map.draw(Panda::CMS::Engine.root.join("config/importmap.rb"))
        end
      end

      initializer "panda.cms.static_assets", after: :load_config_initializers do |app|
        app.config.middleware.insert_before Rack::Sendfile, Rack::Static,
          urls: ["/panda-cms-assets"],
          root: Panda::CMS::Engine.root.join("public")
      end

      # Auto-register AhoyProvider when the ahoy_matey gem is available.
      # When detected, Ahoy replaces LocalProvider as the default data source.
      initializer "panda.cms.ahoy_provider" do
        config.after_initialize do
          if defined?(::Ahoy::Visit)
            Panda::CMS::Analytics.register_provider(:ahoy, Panda::CMS::Analytics::AhoyProvider)
            # Set Ahoy as the default provider unless one has already been explicitly configured
            unless Panda::CMS::Analytics.current_provider_name
              Panda::CMS::Analytics.current_provider_name = :ahoy
              Panda::CMS::Analytics.reset!
            end
            Rails.logger.info "[Panda CMS] Ahoy detected — registered AhoyProvider as default analytics provider"
          end
        end
      end

      # Register search providers for editor link-autocomplete
      initializer "panda_cms.search_providers" do
        ActiveSupport.on_load(:active_record) do
          Panda::Core::SearchRegistry.register(
            name: "pages",
            search_class: Panda::CMS::Page
          )
          Panda::Core::SearchRegistry.register(
            name: "posts",
            search_class: Panda::CMS::Post
          )
        end
      end

      # Configure custom error pages in production-like environments
      # This enables Panda CMS's custom 404, 500, and other error pages
      initializer "panda.cms.custom_error_pages", after: :load_config_initializers do |app|
        app.config.after_initialize do
          unless app.config.consider_all_requests_local
            app.config.exceptions_app = Panda::CMS::ExceptionsApp.new(
              exceptions_app: app.routes
            )
          end
        end
      end
    end

    class MissingBlockError < StandardError; end
    class BlockError < StandardError; end
  end
end

Panda::Core::ModuleRegistry.register(
  gem_name: "panda-cms",
  engine: "Panda::CMS::Engine",
  paths: {
    views: "app/views/panda/cms/**/*.erb",
    components: "app/components/panda/cms/**/*.{rb,erb,js}",
    stylesheets: "app/assets/tailwind/panda/cms/**/*.css"
  }
)
