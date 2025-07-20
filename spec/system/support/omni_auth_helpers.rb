# frozen_string_literal: true

# Set OmniAuth test mode and failure condition
OmniAuth.config.test_mode = true
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

module OmniAuthHelpers
  def login_with_google(user)
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new({
      provider: "google",
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

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google]

    visit "/admin/auth/google/callback"

    sleep(1.0) # Ensure callback is processed and any redirects complete
  end

  def manual_login_with_google(user)
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
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
      provider: "github",
      uid: "123456",
      info: {
        email: user.email,
        name: "#{user.firstname} #{user.lastname}"
      }
    })

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:github]
    visit "/admin/auth/github/callback"
  end

  def login_with_microsoft(user)
    OmniAuth.config.mock_auth[:microsoft] = OmniAuth::AuthHash.new({
      provider: "microsoft",
      uid: "123456",
      info: {
        email: user.email,
        first_name: user.firstname,
        last_name: user.lastname
      }
    })

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:microsoft]
    visit "/admin/auth/microsoft/callback"
  end

  def login_as_admin(firstname: nil, lastname: nil, email: nil)
    user = admin_user
    login_with_google(user)

    # Try to navigate to admin if not already there
    unless page.current_path == "/admin"
      visit "/admin"
    end
  end

  def login_as_user(firstname: nil, lastname: nil, email: nil)
    login_with_google(regular_user)
  end

  def admin_user
    # Use fixture user instead of creating new one
    user = Panda::CMS::User.find_by(email: "admin@example.com")
    if user.nil?
      raise "Admin user not found in database"
    end
    user
  end

  def regular_user
    # Use fixture user instead of creating new one
    Panda::CMS::User.find_by!(email: "user@example.com")
  end
end

RSpec.configure do |config|
  config.include OmniAuthHelpers, type: :system
end
