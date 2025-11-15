# frozen_string_literal: true

module Panda
  module CMS
    class Engine < ::Rails::Engine
      # Asset pipeline and importmap configuration
      module AssetConfig
        extend ActiveSupport::Concern

        included do
          # Asset pipeline configuration
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
                panda/cms/application.js
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
        end
      end
    end
  end
end
