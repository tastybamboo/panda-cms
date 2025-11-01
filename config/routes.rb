# frozen_string_literal: true

Panda::CMS::Engine.routes.draw do
  # Test authentication endpoint moved to panda-core at /admin/test_login/:user_id

  constraints Panda::Core::AdminConstraint.new(&:present?) do
    # CMS-specific dashboard (using Core's admin_path)
    admin_path = Panda::Core.config.admin_path
    get "#{admin_path}/cms", to: "admin/dashboard#show", as: :admin_cms_dashboard

    namespace admin_path.delete_prefix("/").to_sym, path: "#{admin_path}/cms", as: :admin_cms, module: :admin do
      resources :files
      resources :forms, only: %i[index show]
      resources :menus
      resources :pages do
        resources :block_contents, only: %i[update]
      end
      resources :posts

      get "settings", to: "settings#index"

      # Profile management moved to panda-core at /admin/my_profile

      namespace :settings, as: :settings do
        get "bulk_editor", to: "bulk_editor#new"
        post "bulk_editor", to: "bulk_editor#create"
      end
    end
  end

  ### PUBLIC ROUTES ###

  # Authentication routes are now handled by Panda::Core

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
