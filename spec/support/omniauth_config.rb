# Configure OmniAuth for testing
OmniAuth.config.test_mode = true

# Disable request forgery protection for OmniAuth in test
OmniAuth.config.silence_get_warning = true

# Configure mock responses
OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
  provider: "google_oauth2",
  uid: "123456789",
  info: {
    email: "admin@example.com",
    name: "Admin User",
    first_name: "Admin",
    last_name: "User"
  },
  credentials: {
    token: "mock_token",
    expires_at: Time.now + 1.week
  }
})

OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
  provider: "github",
  uid: "123456",
  info: {
    email: "admin@example.com",
    name: "Admin User"
  }
})

OmniAuth.config.mock_auth[:microsoft_graph] = OmniAuth::AuthHash.new({
  provider: "microsoft_graph",
  uid: "123456",
  info: {
    email: "admin@example.com",
    first_name: "Admin",
    last_name: "User"
  }
})

# Configure failure handling
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
