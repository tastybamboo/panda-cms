# frozen_string_literal: true

Rails.application.routes.draw do
  # Mount Panda Core engine for authentication
  mount Panda::Core::Engine => "/"

  # Mount Panda CMS engine
  mount Panda::CMS::Engine => "/"

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
end
