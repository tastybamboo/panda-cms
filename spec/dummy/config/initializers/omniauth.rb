# frozen_string_literal: true

# Configure OmniAuth to allow both GET and POST for authentication
OmniAuth.config.allowed_request_methods = [:get, :post]

# In development, we can be less strict with CSRF
if Rails.env.development?
  OmniAuth.config.test_mode = false
  # Disable OmniAuth's built-in CSRF protection in development
  # Rails' own CSRF protection via form_tag is still active
  OmniAuth.config.request_validation_phase = nil
end
