# frozen_string_literal: true

# Use default cookie-based session store
# This works fine for system tests and avoids Redis compatibility issues
Rails.application.config.session_store :cookie_store, key: "_panda_cms_session"
