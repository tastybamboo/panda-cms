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

      # Auto-compile JavaScript assets for test environments
      initializer "panda_cms.auto_compile_assets", after: :load_config_initializers do |app|
        # Only auto-compile in test or when explicitly requested
        next unless Rails.env.test? || ENV["PANDA_CMS_AUTO_COMPILE"] == "true"

        version = Panda::CMS::VERSION
        js_file = Rails.public_path.join("panda-cms-assets", "panda-cms-#{version}.js")

        unless js_file.exist?
          warn "🐼 [Panda CMS] Auto-compiling JavaScript for test environment..."

          # Run compilation synchronously to ensure it's ready before tests
          require "open3"
          _, stderr, status = Open3.capture3(
            "bundle exec rake app:panda:cms:assets:compile",
            chdir: Panda::CMS::Engine.root.to_s
          )

          if status.success?
            warn "🐼 [Panda CMS] JavaScript compilation successful (#{js_file.size} bytes)"
          else
            warn "🐼 [Panda CMS] JavaScript compilation failed: #{stderr}"
          end
        end
      end
    end

    class MissingBlockError < StandardError; end

    class BlockError < StandardError; end
  end
end
