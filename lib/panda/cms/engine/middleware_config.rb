# frozen_string_literal: true

module Panda
  module CMS
    class Engine < ::Rails::Engine
      # Middleware configuration for serving static assets
      module MiddlewareConfig
        extend ActiveSupport::Concern

        included do
          # Make files in public available to the main app (e.g. /panda-cms-assets/favicon.ico)
          config.middleware.use Rack::Static,
            urls: ["/panda-cms-assets"],
            root: Panda::CMS::Engine.root.join("public")

          # Make JavaScript files available for importmap
          # Serve from app/javascript with proper MIME types
          # Important: Rack::Static strips the matched URL prefix, so we serve from
          # app/javascript and the URL /panda/cms/foo.js will look for app/javascript/panda/cms/foo.js
          config.middleware.use Rack::Static,
            urls: ["/panda/cms"],
            root: Panda::CMS::Engine.root.join("app/javascript"),
            header_rules: [
              # Only set Cache-Control, let Rack::Static handle Content-Type to avoid duplicates
              [:all, {"Cache-Control" => Rails.env.development? ? "no-cache, no-store, must-revalidate" : "public, max-age=31536000"}]
            ]
        end
      end
    end
  end
end
