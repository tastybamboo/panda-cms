# frozen_string_literal: true

# Use cookie_store for all environments
# Cookie-based sessions work fine with Cuprite since we're using the test endpoint
Rails.application.config.session_store :cookie_store,
  key: "_panda_cms_session",
  same_site: :lax,
  secure: Rails.env.production?
