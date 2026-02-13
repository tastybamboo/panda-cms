# frozen_string_literal: true

module Panda
  module CMS
    module Generators
      class InstallGenerator < Rails::Generators::Base
        desc "Install Panda CMS: set up authentication, copy migrations, and configure the initializer"

        def ensure_core_installed
          initializer_path = Rails.root.join("config/initializers/panda.rb")
          unless File.exist?(initializer_path)
            say "Panda Core initializer not found. Running panda:core:install first...", :yellow
            generate "panda:core:install"
          end
        end

        def add_github_gem
          gem "omniauth-github"
        end

        def enable_authentication
          full_path = Rails.root.join("config/initializers/panda.rb")
          return unless File.exist?(full_path)

          content = File.read(full_path)

          # Already configured — skip
          return if content.include?("config.authentication_providers = {")

          auth_block = <<~RUBY.chomp
            config.authentication_providers = {
              github: {
                enabled: true,
                name: "GitHub",
                client_id: if Rails.env.development?
                             "Ov23liFMGyVvRrpuvyTT" # Shared Panda dev app (localhost:3000 only)
                           else
                             Rails.application.credentials.dig(:github, :client_id)
                           end,
                client_secret: if Rails.env.development?
                                 "394a7024d7dd9c0ee0c8540768331d59d9e22477"
                               else
                                 Rails.application.credentials.dig(:github, :client_secret)
                               end
              },
              developer: {
                enabled: true,
                name: "Developer Login"
              }
            }
          RUBY

          # Try to replace the commented-out block from the Core template
          updated = content.sub(
            /  # config\.authentication_providers = \{.*?# \}/m,
            auth_block
          )

          if updated != content
            File.write(full_path, updated)
          else
            say "Could not find commented authentication_providers block in config/initializers/panda.rb.", :yellow
            say "Please add the following inside your Panda::Core.configure block:", :yellow
            say auth_block
          end
        end

        def enable_cms_config
          replace_commented_block(
            "Panda::CMS.configure",
            "# Uncomment after adding gem \"panda-cms\" to your Gemfile:\n# Panda::CMS.configure do |config|\n#   # Require login to view the public site\n#   config.require_login_to_view = false\n# end",
            <<~RUBY.chomp
              Panda::CMS.configure do |config|
                # Require login to view the public site
                config.require_login_to_view = false
              end
            RUBY
          )
        end

        def enable_editor_config
          replace_commented_block(
            "Panda::Editor.configure",
            "# Uncomment after adding gem \"panda-editor\" to your Gemfile:\n# Panda::Editor.configure do |config|\n#   # Additional EditorJS tools to load\n#   # config.editor_js_tools = []\n# end",
            <<~RUBY.chomp
              Panda::Editor.configure do |config|
                # Additional EditorJS tools to load
                # config.editor_js_tools = []
              end
            RUBY
          )
        end

        def copy_migrations
          rake "panda:cms:install:migrations"
        end

        def show_readme
          say ""
          say "Panda CMS installed!", :green
          say ""
          say "Authentication is configured with:"
          say "  - GitHub OAuth  (works immediately in development on localhost:3000)"
          say "  - Developer     (simple name/email form, development only)"
          say ""
          say "Next steps:"
          say "  1. Run: bundle install"
          say "  2. Run: rails db:migrate"
          say "  3. Run: rails db:seed    (creates initial templates, pages, and menus)"
          say "  4. Start your server: bin/dev"
          say "  5. Visit /admin and sign in with GitHub"
          say ""
          say "For production, add your own GitHub OAuth credentials:"
          say "  rails credentials:edit"
          say "  # Add:  github:"
          say "  #          client_id: your_client_id"
          say "  #          client_secret: your_client_secret"
          say ""
          say "The CMS engine auto-mounts itself — no route changes needed."
          say ""
        end

        private

        def replace_commented_block(config_identifier, commented_text, replacement)
          full_path = Rails.root.join("config/initializers/panda.rb")
          return unless File.exist?(full_path)

          content = File.read(full_path)

          # Already configured — skip
          return if content.include?(config_identifier)

          if content.include?(commented_text)
            gsub_file "config/initializers/panda.rb", commented_text, replacement
          else
            append_to_file "config/initializers/panda.rb", "\n#{replacement}\n"
            say "Appended #{config_identifier} block to config/initializers/panda.rb", :yellow
          end
        end
      end
    end
  end
end
