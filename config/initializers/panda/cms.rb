# frozen_string_literal: true

# This file is an example of Panda configuration.
# In your application, this should be at config/initializers/panda.rb
Panda::Core.configure do |config|
  config.admin_path = "/admin"

  config.login_page_title = "Panda Admin"
  config.admin_title = "Panda Admin"

  # Configure authentication providers
  # Uncomment and configure the providers you want to use
  # Don't forget to add the corresponding gems (e.g., omniauth-google-oauth2)
  #
  # config.authentication_providers = {
  #   google_oauth2: {
  #     enabled: true,
  #     name: "Google",  # Display name for the button
  #     client_id: Rails.application.credentials.dig(:google, :client_id),
  #     client_secret: Rails.application.credentials.dig(:google, :client_secret),
  #     options: {
  #       scope: "email,profile",
  #       prompt: "select_account",
  #       hd: "yourdomain.com" # Specify your domain here if you want to restrict admin logins
  #     }
  #   }
  # }

  # Configure the session token cookie name
  config.session_token_cookie = :panda_session

  # Configure the user class for the application
  config.user_class = "Panda::Core::User"

  # Configure the user identity class for the application
  config.user_identity_class = "Panda::Core::UserIdentity"

  # Configure the storage provider (default: :active_storage)
  # config.storage_provider = :active_storage

  # Configure the cache store (default: :memory_store)
  # config.cache_store = :memory_store

  # Configure EditorJS tools (optional)
  # config.editor_js_tools = []
  # config.editor_js_tool_config = {}
end

# Optional CMS-specific configuration
# Panda::CMS.configure do |config|
#   # Site access control
#   config.require_login_to_view = false
# end
