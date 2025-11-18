# frozen_string_literal: true

module Panda
  module CMS
    class Engine < ::Rails::Engine
      # Autoload paths configuration
      module AutoloadConfig
        extend ActiveSupport::Concern

        included do
          # Add services directory to autoload paths
          config.autoload_paths += %W[
            #{root}/app/services
          ]

          # Exclude preview paths from production eager loading
          # Preview classes should only be loaded in development/test environments
          initializer "panda_cms.exclude_previews_from_production", before: :set_autoload_paths do |app|
            if Rails.env.production?
              # Prevent eager loading of preview files in production
              preview_paths = [
                root.join("spec/components/previews").to_s
              ]

              preview_paths.each do |preview_path|
                if Dir.exist?(preview_path)
                  app.config.eager_load_paths.delete(preview_path)
                  ActiveSupport::Dependencies.autoload_paths.delete(preview_path)
                end
              end
            end
          end
        end
      end
    end
  end
end
