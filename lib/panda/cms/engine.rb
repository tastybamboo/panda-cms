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
