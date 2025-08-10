# frozen_string_literal: true

# Set OmniAuth test mode and failure condition
OmniAuth.config.test_mode = true
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

module OmniAuthHelpers
  def clear_omniauth_config
    OmniAuth.config.mock_auth.clear
    Rails.application.env_config.delete("omniauth.auth")
  end

  def login_with_google(user)
    clear_omniauth_config
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new({
      provider: "google",
      uid: user.id,
      info: {
        email: user.email,
        name: user.name
      },
      credentials: {
        token: "mock_token",
        expires_at: Time.now + 1.week
      }
    })

    # Set the Rails env config which the controller checks
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google]

    # Visit the callback URL directly in test mode
    visit "/admin/auth/google/callback"

    # We should be redirected to /admin after successful auth
    expect(page).to have_current_path("/admin", wait: 10)
  end

  def manual_login_with_google(user)
    clear_omniauth_config
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new({
      provider: "google",
      uid: user.id,
      info: {
        email: user.email,
        name: user.name
      },
      credentials: {
        token: "mock_token",
        expires_at: Time.now + 1.week
      }
    })

    visit admin_login_path
    expect(page).to have_css("#button-sign-in-google")
    find("#button-sign-in-google").click

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google]
    visit "/admin"
  end

  def login_with_github(user)
    clear_omniauth_config
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
      provider: "github",
      uid: user.id,
      info: {
        email: user.email,
        name: user.name
      },
      credentials: {
        token: "mock_token",
        expires_at: Time.now + 1.week
      }
    })

    # Set the Rails env config which the controller checks
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:github]

    # Visit the callback URL directly in test mode
    visit "/admin/auth/github/callback"

    # We should be redirected to /admin after successful auth
    expect(page).to have_current_path("/admin", wait: 10)
  end

  def login_with_microsoft(user)
    clear_omniauth_config
    OmniAuth.config.mock_auth[:microsoft] = OmniAuth::AuthHash.new({
      provider: "microsoft",
      uid: user.id,
      info: {
        email: user.email,
        name: user.name
      },
      credentials: {
        token: "mock_token",
        expires_at: Time.now + 1.week
      }
    })

    # Set the Rails env config which the controller checks
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:microsoft]

    # Visit the callback URL directly in test mode
    visit "/admin/auth/microsoft/callback"

    # We should be redirected to /admin after successful auth
    expect(page).to have_current_path("/admin", wait: 10)
  end

  def login_as_admin(firstname: nil, lastname: nil, email: nil)
    user = admin_user
    login_with_google(user)
    # login_with_google already ensures we're at /admin
  end

  def login_as_user(firstname: nil, lastname: nil, email: nil)
    login_with_google(regular_user)
  end

  def admin_user
    # Use fixture user instead of creating new one
    user = Panda::Core::User.find_by(email: "admin@example.com")
    if user.nil?
      raise "Admin user not found in database"
    end
    user
  end

  def regular_user
    # Use fixture user instead of creating new one
    Panda::Core::User.find_by!(email: "user@example.com")
  end
end

RSpec.configure do |config|
  config.include OmniAuthHelpers, type: :system
end
