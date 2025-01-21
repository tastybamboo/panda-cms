require "rubygems"
require "panda/core"
require "panda/core/engine"
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
      initializer "panda_cms.session", before: :load_config_initializers do |app|
        if app.config.middleware.frozen?
          app.config.middleware = app.config.middleware.dup
        end

        app.config.session_store :cookie_store, key: "_panda_cms_session"
        app.config.middleware.use ActionDispatch::Cookies
        app.config.middleware.use ActionDispatch::Session::CookieStore, app.config.session_options
      end

      config.to_prepare do
        ApplicationController.helper(::ApplicationHelper)
      end

      # Set our generators
      config.generators do |g|
        g.orm :active_record, primary_key_type: :uuid
        g.test_framework :rspec, fixture: true
        g.fixture_replacement :factory_bot, dir: "spec/factories"
        g.view_specs false
        g.templates.unshift File.expand_path("../../templates", __FILE__)
      end

      # Make files in public available to the main app (e.g. /panda_cms-assets/favicon.ico)
      config.app_middleware.use(
        Rack::Static,
        urls: ["/panda-cms-assets"],
        root: Panda::CMS::Engine.root.join("public")
      )

      # Custom error handling
      # config.exceptions_app = Panda::CMS::ExceptionsApp.new(exceptions_app: routes)

      initializer "panda_cms.assets" do |app|
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
      initializer "panda_cms.importmap", before: "importmap" do |app|
        if app.config.respond_to?(:importmap)
          # Create a new array if frozen
          if app.config.importmap.paths.frozen?
            app.config.importmap.paths = app.config.importmap.paths.dup
          end

          # Add our paths
          app.config.importmap.paths << root.join("config/importmap.rb")

          # Handle cache sweepers similarly
          if app.config.importmap.cache_sweepers.frozen?
            app.config.importmap.cache_sweepers = app.config.importmap.cache_sweepers.dup
          end
          app.config.importmap.cache_sweepers << root.join("app/javascript")
        end
      end

      config.after_initialize do |app|
        # Append routes to the routes file
        app.routes.append do
          mount Panda::CMS::Engine => "/", :as => "panda_cms"
          post "/_forms/:id", to: "panda/cms/form_submissions#create", as: :panda_cms_form_submit
          get "/_maintenance", to: "panda/cms/errors#error_503", as: :panda_cms_maintenance
          get "/*path", to: "panda/cms/pages#show", as: :panda_cms_page
          root to: "panda/cms/pages#root"
        end
      end

      initializer "#{engine_name}.backtrace_cleaner" do |app|
        engine_root_regex = Regexp.escape(root.to_s + File::SEPARATOR)

        # Clean those ERB lines, we don't need the internal autogenerated
        # ERB method, what we do need (line number in ERB file) is already there
        Rails.backtrace_cleaner.add_filter do |line|
          line.sub(/(\.erb:\d+):in `__.*$/, "\\1")
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

      # Set up ViewComponent and Lookbook
      # config.view_component.component_parent_class = "Panda::CMS::BaseComponent"
      # config.view_component.view_component_path = Panda::CMS::Engine.root.join("lib/components").to_s
      # config.eager_load_paths << Panda::CMS::Engine.root.join("lib/components").to_s
      # config.view_component.generate.sidecar = true
      # config.view_component.generate.preview = truexw
      # config.view_component.preview_paths ||= []
      # config.view_component.preview_paths << Panda::CMS::Engine.root.join("lib/component_previews").to_s
      # config.view_component.generate.preview_path = "lib/component_previews"

      # Set up authentication
      initializer "panda_cms.omniauth", before: "omniauth" do |app|
        app.config.session_store :cookie_store, key: "_panda_cms_session"
        app.config.middleware.use ActionDispatch::Cookies
        app.config.middleware.use ActionDispatch::Session::CookieStore, app.config.session_options

        OmniAuth.config.logger = Rails.logger

        # TODO: Move this to somewhere more sensible?
        # Define the mapping of our provider "names" to the OmniAuth strategies and configuration
        auth_path = "#{Panda::CMS.route_namespace}/auth"
        callback_path = "/callback"
        available_providers = {
          microsoft: {
            strategy: :microsoft_graph,
            defaults: {
              name: "microsoft",
              # Setup at the following URL:
              # https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade
              client_id: Rails.application.credentials.dig(:microsoft, :client_id),
              client_secret: Rails.application.credentials.dig(:microsoft, :client_secret),
              # Don't change this or the sky will fall on your head
              # https://github.com/synth/omniauth-microsoft_graph/tree/main?tab=readme-ov-file#domain-verification
              skip_domain_verification: false,
              # If your application is single-tenanted, replace "common" with your tenant (directory) ID
              # from https://portal.azure.com/#settings/directory, otherwise you'll likely want to leave
              # these settings unchanged
              client_options: {
                site: "https://login.microsoftonline.com/",
                token_url: "common/oauth2/v2.0/token",
                authorize_url: "common/oauth2/v2.0/authorize"
              },
              # If you assign specific users or groups, you will likely want to set this to
              # true to enable auto-provisioning
              create_account_on_first_login: false,
              create_admin_account_on_first_login: false,
              # Don't hide this provider from the login page
              hidden: false
            }
          },
          google: {
            strategy: :google_oauth2,
            defaults: {
              name: "google",
              # Setup at the following URL: https://console.developers.google.com/
              client_id: Rails.application.credentials.dig(:google, :client_id),
              client_secret: Rails.application.credentials.dig(:google, :client_secret),
              # If you assign specific users or groups, you will likely want to set this to
              # true to enable auto-provisioning
              create_account_on_first_login: false,
              create_admin_account_on_first_login: false,
              # Options we need
              scope: "email, profile",
              image_aspect_ratio: "square",
              image_size: 150,
              # Worth setting select_account as default, as many people have multiple Google accounts now:
              prompt: "select_account",
              # You should probably also set the 'hd' option, huh?,
              # Don't hide this provider from the login page
              hidden: false
            }
          },
          github: {
            strategy: :github,
            defaults: {
              name: "github",
              # Setup at the following URL: https://github.com/settings/applications/new
              # with a callback of
              # In the meantime, as long as you're set to /admin as your login path, and on
              # http://localhost:3000, you can use these for a first login :)
              client_id: Rails.application.credentials.dig(:github, :client_id),
              client_secret: Rails.application.credentials.dig(:github, :client_secret),
              scope: "user:email,read:user",
              create_account_on_first_login: false,
              create_admin_account_on_first_login: false,
              # Don't hide this provider from the login page
              hidden: false
            }
          }
        }

        available_providers.each do |provider, options|
          if Panda::CMS.config.authentication.dig(provider, :enabled)
            auth_path = auth_path.starts_with?("/") ? auth_path : "/#{auth_path}"
            options[:defaults][:path_prefix] = auth_path

            options[:defaults][:redirect_uri] = if Rails.env.test?
              "#{Capybara.app_host}#{auth_path}/#{provider}#{callback_path}"
            else
              "#{Panda::CMS.config.url}#{auth_path}/#{provider}#{callback_path}"
            end

            provider_config = options[:defaults].merge(Panda::CMS.config.authentication[provider])

            app.config.middleware.use OmniAuth::Builder do
              provider options[:strategy], provider_config
            end
          end
        end
      end

      config.before_initialize do |app|
        # Default configuration
        Panda::CMS.configure do |config|
          # Array of additional EditorJS tools to load
          # Example: [{ url: "https://cdn.jsdelivr.net/npm/@editorjs/image@latest" }]
          config.editor_js_tools ||= []

          # Hash of EditorJS tool configurations
          # Example: { image: { class: 'ImageTool', config: { ... } } }
          config.editor_js_tool_config ||= {}
        end
      end
    end

    class MissingBlockError < StandardError; end

    class BlockError < StandardError; end
  end
end
