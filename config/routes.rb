# frozen_string_literal: true

Panda::CMS::Engine.routes.draw do
  # Test authentication endpoint moved to panda-core at /admin/test_login/:user_id

  constraints Panda::Core::AdminConstraint.new do
    # CMS-specific dashboard (using Core's admin_path)
    admin_path = Panda::Core.config.admin_path
    get "#{admin_path}/cms", to: "admin/dashboard#show", as: :admin_cms_dashboard

    namespace admin_path.delete_prefix("/").to_sym, path: "#{admin_path}/cms", as: :admin_cms, module: :admin do
      resources :files
      resources :forms do
        resources :form_submissions, only: [:show], as: :submissions, path: "submissions"
      end
      post "link_metadata", to: "link_metadata#create", as: :link_metadata
      resources :menus do
        post :toggle_pin, on: :member
      end
      resources :pages do
        resources :block_contents, only: %i[update]
        post :reorder, on: :member
        get :children, on: :member
      end
      resources :posts
      resources :post_categories
      resources :redirects, except: :show

      get "settings", to: "settings#index"

      # Profile management moved to panda-core at /admin/my_profile

      namespace :settings, as: :settings do
        get "bulk_editor", to: "bulk_editor#new"
        post "bulk_editor", to: "bulk_editor#create"

        get "social_sharing", to: "social_sharing#index", as: :social_sharing
        patch "social_sharing/:id", to: "social_sharing#update", as: :social_sharing_network
      end
    end
  end

  ### PUBLIC ROUTES ###

  # Sitemap
  get "sitemap", to: "sitemaps#index", as: :sitemap, defaults: {format: :xml}, constraints: {format: :xml}

  # Authentication routes are now handled by Panda::Core

  # Error pages (403, 404, 500, etc.)
  match "/403", to: "errors#show", via: :all, defaults: {code: "403"}
  match "/404", to: "errors#show", via: :all, defaults: {code: "404"}
  match "/422", to: "errors#show", via: :all, defaults: {code: "422"}
  match "/500", to: "errors#show", via: :all, defaults: {code: "500"}
  match "/503", to: "errors#show", via: :all, defaults: {code: "503"}

  ### APPENDED ROUTES ###

  # TODO: Allow multiple types of post in future
  if Panda::CMS.config.posts[:enabled]
    get Panda::CMS.config.posts[:prefix], to: "posts#index", as: :posts

    # Route for date-based URLs that won't encode slashes
    get "#{Panda::CMS.config.posts[:prefix]}/:year/:month/:slug",
      to: "posts#show",
      as: :post_with_date,
      constraints: {
        year: /\d{4}/,
        month: /\d{2}/,
        slug: %r{[^/]+},
        format: /html|json|xml/
      }

    # Route for non-date URLs
    get "#{Panda::CMS.config.posts[:prefix]}/:slug",
      to: "posts#show",
      as: :post,
      constraints: {
        slug: %r{[^/]+},
        format: /html|json|xml/
      }

    # Route for category archive
    get "#{Panda::CMS.config.posts[:prefix]}/category/:category_slug",
      to: "posts#by_category",
      as: :posts_by_category,
      constraints: {
        category_slug: /[a-z0-9-]+/,
        format: /html|json|xml/
      }

    # Route for month archive
    get "#{Panda::CMS.config.posts[:prefix]}/:year/:month",
      to: "posts#by_month",
      as: :posts_by_month,
      constraints: {
        year: /\d{4}/,
        month: /\d{2}/,
        format: /html|json|xml/
      }
  end

  # See lib/panda/cms/engine.rb
end
