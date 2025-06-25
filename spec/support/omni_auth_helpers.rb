# frozen_string_literal: true

module OmniAuthHelpers
  def login_as_admin
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "123456789",
      info: {
        email: "admin@example.com",
        name: "Admin User"
      }
    )
    visit "/auth/google_oauth2"
  end

  def login_as_user
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "987654321",
      info: {
        email: "user@example.com",
        name: "Regular User"
      }
    )
    visit "/auth/google_oauth2"
  end
end
