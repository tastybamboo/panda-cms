# frozen_string_literal: true

module Panda
  module CMS
    class Engine < ::Rails::Engine
      # ViewComponent configuration
      module ViewComponentConfig
        extend ActiveSupport::Concern

        included do
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
        end
      end
    end
  end
end
