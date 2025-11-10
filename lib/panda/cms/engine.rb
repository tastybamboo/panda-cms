# frozen_string_literal: true

require "rubygems"
require "panda/core"
require "panda/core/engine"
require "panda/editor"
require "panda/editor/engine"
require "panda/cms/railtie"

require "invisible_captcha"

# Load engine configuration modules
require_relative "engine/middleware_config"
require_relative "engine/asset_config"
require_relative "engine/route_config"
require_relative "engine/core_config"
require_relative "engine/view_component_config"
require_relative "engine/backtrace_config"

module Panda
  module CMS
    class Engine < ::Rails::Engine
      isolate_namespace Panda::CMS

      # For testing: Don't expose engine migrations since we use "copy to host app" strategy
      # In test environment, migrations should be copied to the dummy app
      if Rails.env.test?
        config.paths["db/migrate"] = []
      end

      # Include configuration modules
      include MiddlewareConfig
      include AssetConfig
      include RouteConfig
      include CoreConfig
      include ViewComponentConfig
      include BacktraceConfig

      # Add services directory to autoload paths
      config.autoload_paths += %W[
        #{root}/app/services
      ]

      # Session configuration is left to the consuming application
      # The CMS engine does not impose session store requirements

      config.to_prepare do
        ApplicationController.helper(::ApplicationHelper)
        ApplicationController.helper(Panda::CMS::AssetHelper)
      end

      # Set our generators
      config.generators do |g|
        g.orm :active_record, primary_key_type: :uuid
        g.test_framework :rspec, fixture: true
        g.fixture_replacement nil
        g.view_specs false
        g.templates.unshift File.expand_path("../templates", __dir__)
      end

      # Custom error handling
      # config.exceptions_app = Panda::CMS::ExceptionsApp.new(exceptions_app: routes)

      # Authentication is now handled by Panda::Core::Engine
    end

    class MissingBlockError < StandardError; end

    class BlockError < StandardError; end
  end
end
