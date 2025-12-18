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
        end
      end
    end
  end
end
