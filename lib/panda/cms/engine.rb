# frozen_string_literal: true

require "rubygems"
require "panda/core"
require "panda/core/engine"
require "panda/editor"
require "panda/editor/engine"
require "panda/cms/railtie"

require "invisible_captcha"

module Panda
  module CMS
    class Engine < ::Rails::Engine
      isolate_namespace Panda::CMS

      # Add services directory to autoload paths
      config.autoload_paths += %W[
        #{root}/app/services
      ]

      # Basic session setup only
      initializer "panda.cms.session", before: :load_config_initializers do |app|
        app.config.middleware = app.config.middleware.dup if app.config.middleware.frozen?

        # Use Redis for sessions in test environment to support Capybara cross-process auth
        # Use cookie store in other environments for simplicity
        if Rails.env.test?
          require 'rack/session/redis'
          app.config.session_store Rack::Session::Redis,
            redis_server: "redis://localhost:6379/1",
            expire_after: 1.hour,
            key: "_panda_cms_session"
        else
          app.config.session_store :cookie_store, key: "_panda_cms_session"
          app.config.middleware.use ActionDispatch::Cookies
          app.config.middleware.use ActionDispatch::Session::CookieStore, app.config.session_options
        end
      end

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

      # Make files in public available to the main app (e.g. /panda_cms-assets/favicon.ico)
      config.app_middleware.use(
        Rack::Static,
        urls: ["/panda-cms-assets"],
        root: Panda::CMS::Engine.root.join("public")
      )

      # Make JavaScript files available for importmap
      # Serve from app/javascript with proper MIME types
      config.app_middleware.use(
        Rack::Static,
        urls: ["/panda/cms"],
        root: Panda::CMS::Engine.root.join("app/javascript"),
        header_rules: [
          [:all, {"Cache-Control" => Rails.env.development? ? "no-cache, no-store, must-revalidate" : "public, max-age=31536000",
                  "Content-Type" => "text/javascript; charset=utf-8"}]
        ]
      )

      # Custom error handling
      # config.exceptions_app = Panda::CMS::ExceptionsApp.new(exceptions_app: routes)

      initializer "panda.cms.assets" do |app|
        if Rails.configuration.respond_to?(:assets)
          # Add JavaScript paths
          app.config.assets.paths << root.join("app/javascript")
          app.config.assets.paths << root.join("app/javascript/panda")
          app.config.assets.paths << root.join("app/javascript/panda/cms")
          app.config.assets.paths << root.join("app/javascript/panda/cms/controllers")

          # Make sure these files are precompiled
          app.config.assets.precompile += %w[
            panda_cms_manifest.js
            panda/cms/controllers/**/*.js
            panda/cms/application_panda_cms.js
          ]
        end
      end

      # Add importmap paths from the engine
      initializer "panda.cms.importmap", before: "importmap" do |app|
        if app.config.respond_to?(:importmap)
          # Create a new array if frozen
          app.config.importmap.paths = app.config.importmap.paths.dup if app.config.importmap.paths.frozen?

          # Add our paths
          app.config.importmap.paths << root.join("config/importmap.rb")

          # Handle cache sweepers similarly
          if app.config.importmap.cache_sweepers.frozen?
            app.config.importmap.cache_sweepers = app.config.importmap.cache_sweepers.dup
          end
          app.config.importmap.cache_sweepers << root.join("app/javascript")
        end
      end

      # Auto-mount disabled for development server compatibility
      # Puma cluster preloading interferes with after_initialize route mounting
      # For manual mounting example, see spec/dummy/config/routes.rb
      # config.after_initialize do |app|
      #   # Append routes to the routes file
      #   app.routes.append do
      #     mount Panda::CMS::Engine => "/", :as => "panda_cms"
      #     post "/_forms/:id", to: "panda/cms/form_submissions#create", as: :panda_cms_form_submit
      #     get "/_maintenance", to: "panda/cms/errors#error_503", as: :panda_cms_maintenance
      #
      #     # Catch-all route for CMS pages, but exclude admin paths
      #     admin_path = Panda::Core.config.admin_path.delete_prefix("/")
      #     constraints = ->(request) { !request.path.start_with?("/#{admin_path}") }
      #     get "/*path", to: "panda/cms/pages#show", as: :panda_cms_page, constraints: constraints
      #
      #     root to: "panda/cms/pages#root"
      #   end
      # end

      initializer "#{engine_name}.backtrace_cleaner" do |_app|
        engine_root_regex = Regexp.escape(root.to_s + File::SEPARATOR)

        # Clean those ERB lines, we don't need the internal autogenerated
        # ERB method, what we do need (line number in ERB file) is already there
        Rails.backtrace_cleaner.add_filter do |line|
          line.sub(/(\.erb:\d+):in `__.*$/, '\\1')
        end

        # Remove our own engine's path prefix, even if it's
        # being used from a local path rather than the gem directory.
        Rails.backtrace_cleaner.add_filter do |line|
          line.sub(/^#{engine_root_regex}/, "#{engine_name} ")
        end

        # Keep Umlaut's own stacktrace in the backtrace -- we have to remove Rails
        # silencers and re-add them how we want.
        Rails.backtrace_cleaner.remove_silencers!

        # Silence what Rails silenced, UNLESS it looks like
        # it's from Umlaut engine
        Rails.backtrace_cleaner.add_silencer do |line|
          (line !~ Rails::BacktraceCleaner::APP_DIRS_PATTERN) &&
            (line !~ /^#{engine_root_regex}/) &&
            (line !~ /^#{engine_name} /)
        end
      end

      # Set up ViewComponent
      initializer "panda.cms.view_component" do |app|
        app.config.view_component.preview_paths ||= []
        app.config.view_component.preview_paths << root.join("spec/components/previews")
        app.config.view_component.generate.sidecar = true
        app.config.view_component.generate.preview = true

        # Add preview directories to autoload paths in development
        if Rails.env.development?
          # Handle frozen autoload_paths array
          if app.config.autoload_paths.frozen?
            app.config.autoload_paths = app.config.autoload_paths.dup
          end
          app.config.autoload_paths << root.join("spec/components/previews")
        end
      end

      # Authentication is now handled by Panda::Core::Engine

      # Configure Core for CMS (runs before app initializers so apps can override)
      initializer "panda.cms.configure_core", before: :load_config_initializers do |app|
        Panda::Core.configure do |config|
          # Core now provides the admin interface foundation
          # Apps using CMS can customize login_logo_path, login_page_title, etc. in their own initializers

          # Register CMS navigation items
          config.admin_navigation_items = ->(user) {
            items = []

            # Dashboard
            items << {
              path: "#{config.admin_path}/cms",
              label: "Dashboard",
              icon: "fa-solid fa-house"
            }

            # Pages
            items << {
              path: "#{config.admin_path}/cms/pages",
              label: "Pages",
              icon: "fa-solid fa-file"
            }

            # Collections (if enabled)
            if Panda::CMS::Features.enabled?(:collections)
              items << {
                path: "#{config.admin_path}/cms/collections",
                label: "Collections",
                icon: "fa-solid fa-table-cells"
              }
            end

            # Posts
            items << {
              path: "#{config.admin_path}/cms/posts",
              label: "Posts",
              icon: "fa-solid fa-newspaper"
            }

            # Forms
            items << {
              path: "#{config.admin_path}/cms/forms",
              label: "Forms",
              icon: "fa-solid fa-inbox"
            }

            # Menus
            items << {
              path: "#{config.admin_path}/cms/menus",
              label: "Menus",
              icon: "fa-solid fa-bars"
            }

            # Settings
            items << {
              path: "#{config.admin_path}/cms/settings",
              label: "Settings",
              icon: "fa-solid fa-gear"
            }

            items
          }

          # Redirect to CMS dashboard after login
          # Apps can override this if they want different behavior
          config.dashboard_redirect_path = -> { "#{Panda::Core.config.admin_path}/cms" }

          # Customize initial breadcrumb
          config.initial_admin_breadcrumb = ->(controller) {
            # Use CMS dashboard path - just use the string path
            ["Admin", "#{config.admin_path}/cms"]
          }

          # Dashboard widgets
          config.admin_dashboard_widgets = ->(user) {
            widgets = []

            # Add CMS statistics widgets if CMS is available
            if defined?(Panda::CMS)
              widgets << Panda::CMS::Admin::StatisticsComponent.new(
                metric: "Views Today",
                value: Panda::CMS::Visit.group_by_day(:visited_at, last: 1).count.values.first || 0
              )
              widgets << Panda::CMS::Admin::StatisticsComponent.new(
                metric: "Views Last Week",
                value: Panda::CMS::Visit.group_by_week(:visited_at, last: 1).count.values.first || 0
              )
              widgets << Panda::CMS::Admin::StatisticsComponent.new(
                metric: "Views Last Month",
                value: Panda::CMS::Visit.group_by_month(:visited_at, last: 1).count.values.first || 0
              )
            end

            widgets
          }
        end
      end
    end

    class MissingBlockError < StandardError; end

    class BlockError < StandardError; end
  end
end
