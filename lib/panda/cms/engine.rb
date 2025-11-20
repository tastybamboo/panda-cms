# frozen_string_literal: true

require "rubygems"
require "panda/core"
require "panda/core/engine"
require "panda/editor"
require "panda/editor/engine"
require "panda/cms/railtie"

require "invisible_captcha"

# Load engine configuration modules
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

      # Include shared configuration modules from panda-core
      include Panda::Core::Shared::InflectionsConfig
      include Panda::Core::Shared::GeneratorConfig

      # Include CMS-specific configuration modules
      include AutoloadConfig
      include AssetConfig
      include RouteConfig
      include CoreConfig
      include HelperConfig
      include BacktraceConfig

      # Session configuration is left to the consuming application
      # The CMS engine does not impose session store requirements

      # Custom error handling
      # config.exceptions_app = Panda::CMS::ExceptionsApp.new(exceptions_app: routes)

      # Authentication is now handled by Panda::Core::Engine

      # Load the engine's importmap
      # This keeps the engine's JavaScript separate from the app's importmap
      initializer "panda_cms.importmap", before: "importmap" do |app|
        Panda::CMS.importmap = Importmap::Map.new.tap do |map|
          map.draw(Panda::CMS::Engine.root.join("config/importmap.rb"))
        end
      end

      # Static asset middleware for serving public files
      # JavaScript serving is handled by Panda::Core::ModuleRegistry::JavaScriptMiddleware
      initializer "panda.cms.static_assets" do |app|
        # Serve public assets (CSS, images, etc.)
        # JavaScript is served by ModuleRegistry's JavaScriptMiddleware in panda-core
        app.config.middleware.use Rack::Static,
          urls: ["/panda-cms-assets"],
          root: Panda::CMS::Engine.root.join("public")
      end
    end

    class MissingBlockError < StandardError; end

    class BlockError < StandardError; end
  end
end

# Register CMS module with ModuleRegistry for JavaScript serving
Panda::Core::ModuleRegistry.register(
  gem_name: "panda-cms",
  engine: "Panda::CMS::Engine",
  paths: {
    views: "app/views/panda/cms/**/*.erb",
    components: "app/components/panda/cms/**/*.rb",
    stylesheets: "app/assets/tailwind/panda/cms/**/*.css"
    # JavaScript paths are auto-discovered from config/importmap.rb
  }
)
