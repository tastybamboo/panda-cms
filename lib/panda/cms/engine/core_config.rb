# frozen_string_literal: true

module Panda
  module CMS
    class Engine < ::Rails::Engine
      # Configuration for Panda::Core integration (navigation, breadcrumbs, widgets)
      module CoreConfig
        extend ActiveSupport::Concern

        included do
          # Configure Core for CMS (runs before app initializers so apps can override)
          initializer "panda.cms.configure_core", before: :load_config_initializers do |app|
            Panda::Core.configure do |config|
              # Core now provides the admin interface foundation
              # Apps using CMS can customize login_logo_path, login_page_title, etc. in their own initializers

              # Register CMS navigation items with nested structure
              config.admin_navigation_items = ->(user) {
                items = []

                # Dashboard
                items << {
                  path: "#{config.admin_path}/cms",
                  label: "Dashboard",
                  icon: "fa-solid fa-house"
                }

                # Content group - Pages, Posts, Collections
                content_children = [
                  { label: "Pages", path: "#{config.admin_path}/cms/pages" },
                  { label: "Posts", path: "#{config.admin_path}/cms/posts" }
                ]

                # Add Collections if enabled
                if Panda::CMS::Features.enabled?(:collections)
                  content_children << { label: "Collections", path: "#{config.admin_path}/cms/collections" }
                end

                items << {
                  label: "Content",
                  icon: "fa-solid fa-file-lines",
                  children: content_children
                }

                # Forms & Files group
                items << {
                  label: "Forms & Files",
                  icon: "fa-solid fa-folder",
                  children: [
                    { label: "Forms", path: "#{config.admin_path}/cms/forms" },
                    { label: "Files", path: "#{config.admin_path}/cms/files" }
                  ]
                }

                # Menus (standalone)
                items << {
                  path: "#{config.admin_path}/cms/menus",
                  label: "Menus",
                  icon: "fa-solid fa-bars"
                }

                # Tools group
                items << {
                  label: "Tools",
                  icon: "fa-solid fa-wrench",
                  children: [
                    { label: "Import/Export", path: "#{config.admin_path}/cms/tools/import-export" }
                  ]
                }

                # Settings (standalone)
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

                # TODO: Add CMS statistics widgets when StatisticsComponent is implemented
                # This was removed along with Pro code migration

                widgets
              }
            end
          end
        end
      end
    end
  end
end
