# frozen_string_literal: true

Rails.application.routes.draw do
  # Serve CMS static assets (workaround for engine public directory not being served in dummy app)
  get "/panda-cms-assets/*path", to: proc { |env|
    request = ActionDispatch::Request.new(env)
    asset_path = Panda::CMS::Engine.root.join("public", "panda-cms-assets", request.params[:path])

    if File.exist?(asset_path) && File.file?(asset_path)
      content_type = case File.extname(asset_path)
                     when ".png" then "image/png"
                     when ".jpg", ".jpeg" then "image/jpeg"
                     when ".svg" then "image/svg+xml"
                     when ".css" then "text/css"
                     when ".js" then "text/javascript"
                     when ".json" then "application/json"
                     when ".ico" then "image/x-icon"
                     when ".webmanifest" then "application/manifest+json"
                     else "application/octet-stream"
                     end

      [200, {"Content-Type" => content_type}, [File.read(asset_path)]]
    else
      [404, {"Content-Type" => "text/plain"}, ["Asset not found: #{request.params[:path]}"]]
    end
  }

  # Mount both engines at root - they use different internal path prefixes
  # Core provides /admin/login, /admin/, /admin/my_profile
  # CMS provides /admin/cms/pages, /posts/*, etc.
  mount Panda::Core::Engine => "/", as: "panda_core"
  mount Panda::CMS::Engine => "/", as: "panda_cms"

  # CMS public routes
  post "/_forms/:id", to: "panda/cms/form_submissions#create", as: :panda_cms_form_submit
  get "/_maintenance", to: "panda/cms/errors#error_503", as: :panda_cms_maintenance

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', :as => :rails_health_check

  # Test-only route that renders a page using panda_cms_collection_items
  get '/collections-demo', to: 'collections_demo#index'

  # Development-only test login
  if Rails.env.development?
    get '/admin/test_login/:id', to: 'test_login#show', as: :test_login
  end

  # CMS catch-all for pages (must be last)
  admin_path = Panda::Core.config.admin_path.delete_prefix("/")
  constraints = ->(request) {
    !request.path.start_with?("/#{admin_path}") &&
    !request.path.start_with?("/panda-cms-assets/")
  }
  get "/*path", to: "panda/cms/pages#show", as: :panda_cms_page, constraints: constraints

  root to: "panda/cms/pages#root"
end
