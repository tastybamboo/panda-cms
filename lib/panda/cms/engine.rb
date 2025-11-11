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

        # Use timestamp for cache busting in dev/test
        timestamp = Time.now.to_i
        assets_dir = Rails.public_path.join("panda-cms-assets")
        FileUtils.mkdir_p(assets_dir)

        # Check if any compiled JS exists (timestamp-based)
        existing_js = Dir[assets_dir.join("panda-cms-*.js")].reject { |f| File.basename(f) =~ /^\d+\./ } # Skip manifest files

        if existing_js.empty?
          warn "🐼 [Panda CMS] Auto-compiling JavaScript for test environment..."

          # Run compilation synchronously with timestamp
          # Set VERSION_OVERRIDE to use timestamp instead of semantic version
          require "open3"
          _, stderr, status = Open3.capture3(
            {"VERSION_OVERRIDE" => timestamp.to_s},
            "bundle exec rake app:panda:cms:assets:compile",
            chdir: Panda::CMS::Engine.root.to_s
          )

          timestamped_js = assets_dir.join("panda-cms-#{timestamp}.js")

          if status.success? && timestamped_js.exist?
            warn "🐼 [Panda CMS] JavaScript compilation successful (#{timestamped_js.size} bytes)"
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
