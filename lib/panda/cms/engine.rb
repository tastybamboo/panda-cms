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
require_relative "engine/middleware_config"
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
      include MiddlewareConfig
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

      # Panda CMS uses importmaps for JavaScript (no compilation needed)
      # All JavaScript controllers are served via Rack::Static middleware
      # from the engine's app/javascript directory
    end

    class MissingBlockError < StandardError; end

    class BlockError < StandardError; end
  end
end

# Register CMS module with panda-core for asset compilation
Panda::Core::ModuleRegistry.register(
  gem_name: "panda-cms",
  engine: "Panda::CMS::Engine",
  paths: {
    views: "app/views/panda/cms/**/*.erb",
    components: "app/components/panda/cms/**/*.rb"
    # JavaScript paths are auto-discovered from config/importmap.rb
  }
)
