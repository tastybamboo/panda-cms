# frozen_string_literal: true

Rails.application.routes.draw do
  # Mount Panda Core engine for authentication at root
  # This provides /admin routes for authentication and admin UI
  mount Panda::Core::Engine => "/"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', :as => :rails_health_check

  # Test-only route that renders a page using panda_cms_collection_items
  get '/collections-demo', to: 'collections_demo#index'

  # Mount Panda CMS engine - this adds:
  # - Admin CMS routes under /admin/cms (pages, posts, menus, etc.)
  # - Form submission handler at /_forms/:id
  # - Catch-all route for CMS pages at /*path
  mount Panda::CMS::Engine => "/"
end
