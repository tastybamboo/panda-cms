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
          # Use both /panda and /panda/cms for compatibility with file structure
          config.middleware.use Rack::Static,
            urls: ["/panda", "/panda/cms"],
            root: Panda::CMS::Engine.root.join("app/javascript"),
            header_rules: [
              [:all, {"Cache-Control" => Rails.env.development? ? "no-cache, no-store, must-revalidate" : "public, max-age=31536000",
                      "Content-Type" => "text/javascript; charset=utf-8"}]
            ]
        end
      end
    end
  end
end
