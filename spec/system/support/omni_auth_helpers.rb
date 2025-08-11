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

  def login_with_google(user, expect_success: true)
    clear_omniauth_config
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: user.id,
      info: {
        email: user.email,
        name: "#{user.firstname} #{user.lastname}"
      },
      credentials: {
        token: "mock_token",
        expires_at: Time.now + 1.week
      }
    })

    # Set the Rails env config which the controller checks
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]

    # Visit the callback URL directly in test mode
    visit "/admin/auth/google_oauth2/callback"

    # Only check for successful redirect if expected
    if expect_success
      expect(page).to have_current_path("/admin/cms", wait: 10)
    end
  end

  def manual_login_with_google(user)
    clear_omniauth_config
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: user.id,
      info: {
        email: user.email,
        name: "#{user.firstname} #{user.lastname}"
      },
      credentials: {
        token: "mock_token",
        expires_at: Time.now + 1.week
      }
    })

    visit panda_core.admin_login_path
    expect(page).to have_css("#button-sign-in-google_oauth2")
    find("#button-sign-in-google_oauth2").click

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
    visit "/admin"
  end

  def login_with_github(user, expect_success: true)
    clear_omniauth_config
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
      provider: "github",
      uid: user.id,
      info: {
        email: user.email,
        name: "#{user.firstname} #{user.lastname}"
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

    # Only check for successful redirect if expected
    if expect_success
      expect(page).to have_current_path("/admin/cms", wait: 10)
    end
  end

  def login_with_microsoft(user, expect_success: true)
    clear_omniauth_config
    OmniAuth.config.mock_auth[:microsoft_graph] = OmniAuth::AuthHash.new({
      provider: "microsoft_graph",
      uid: user.id,
      info: {
        email: user.email,
        name: "#{user.firstname} #{user.lastname}"
      },
      credentials: {
        token: "mock_token",
        expires_at: Time.now + 1.week
      }
    })

    # Set the Rails env config which the controller checks
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:microsoft_graph]

    # Visit the callback URL directly in test mode
    visit "/admin/auth/microsoft_graph/callback"

    # Only check for successful redirect if expected
    if expect_success
      expect(page).to have_current_path("/admin/cms", wait: 10)
    end
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
    # Create admin user if it doesn't exist
    Panda::Core::User.find_or_create_by!(email: "admin@example.com") do |user|
      user.firstname = "Admin"
      user.lastname = "User"
      user.admin = true
    end
  end

  def regular_user
    # Create regular user if it doesn't exist
    Panda::Core::User.find_or_create_by!(email: "user@example.com") do |user|
      user.firstname = "Regular"
      user.lastname = "User"
      user.admin = false
    end
  end
end

RSpec.configure do |config|
  config.include OmniAuthHelpers, type: :system
end
