# Configure OmniAuth for testing
OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:default] = nil

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

# Configure failure handling
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

# Configure Panda CMS authentication
Panda::CMS.configure do |config|
  config.authentication = {
    google: {
      enabled: true,
      client_id: "test_id",
      client_secret: "test_secret",
      create_account_on_first_login: true
    },
    microsoft: {
      enabled: true,
      client_id: "test_id",
      client_secret: "test_secret",
      create_account_on_first_login: true
    },
    github: {
      enabled: true,
      client_id: "test_id",
      client_secret: "test_secret",
      create_account_on_first_login: true
    }
  }
end
