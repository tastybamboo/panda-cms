# frozen_string_literal: true

module Panda
  module CMS
    class Engine < ::Rails::Engine
      # Route mounting and configuration
      module RouteConfig
        extend ActiveSupport::Concern

        included do
          # Auto-mount CMS routes
          config.after_initialize do |app|
            # Append routes to the routes file
            app.routes.append do
              mount Panda::CMS::Engine => "/", :as => "panda_cms"
              post "/_forms/:id", to: "panda/cms/form_submissions#create", as: :panda_cms_form_submit
              get "/_maintenance", to: "panda/cms/errors#error_503", as: :panda_cms_maintenance

              # Catch-all route for CMS pages, but exclude admin paths and assets
              admin_path = Panda::Core.config.admin_path.delete_prefix("/")
              constraints = ->(request) {
                !request.path.start_with?("/#{admin_path}") &&
                  !request.path.start_with?("/panda-cms-assets/")
              }
              get "/*path", to: "panda/cms/pages#show", as: :panda_cms_page, constraints: constraints

              root to: "panda/cms/pages#root"
            end
          end
        end
      end
    end
  end
end
