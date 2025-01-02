# Set OmniAuth test mode and failure condition
OmniAuth.config.test_mode = true
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

module OmniAuthHelpers
  def debug(message)
    puts "[DEBUG] #{message}" if ENV["DEBUG"]
  end

  def debug_page_state
    return unless ENV["DEBUG"]
    debug "Current URL: #{page.current_url}"
    debug "Current Path: #{page.current_path}"
    debug "Page Title: #{page.title}"
    debug "Page HTML snippet:"
    debug page.body[0..500] # First 500 chars of HTML

    # Log any JS console errors
    if page.driver.browser.respond_to?(:manage)
      console_logs = page.driver.browser.manage.logs.get(:browser)
      if console_logs.present?
        debug "Browser Console Logs:"
        console_logs.each { |log| debug "  #{log.message}" }
      end
    end
  rescue => e
    debug "Error capturing page state: #{e.message}"
  end

  def login_with_google(user)
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new({
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

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google]
    visit "/admin/auth/google/callback"
    sleep(0.5)  # Ensure callback is processed
  end

  def manual_login_with_google(user)
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
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
    expect(page).to have_content("Dashboard", wait: 1)
  end

  def login_as_user(firstname: nil, lastname: nil, email: nil)
    login_with_google(regular_user)
  end

  def admin_user
    Panda::CMS::User.find_or_create_by!(
      firstname: "Admin",
      lastname: "User",
      email: "admin@example.com",
      admin: true,
      image_url: "/panda-cms-assets/panda-nav.png"
    )
  end

  def regular_user
    Panda::CMS::User.find_or_create_by!(
      firstname: "Regular",
      lastname: "User",
      email: "regular@example.com",
      admin: false,
      image_url: "/panda-cms-assets/panda-nav.png"
    )
  end
end

RSpec.configure do |config|
  config.include OmniAuthHelpers, type: :system

  config.after(:each, type: :system) do |example|
    if example.exception
      debug "Test failed: #{example.full_description}"
      debug "Error: #{example.exception.message}"
      debug_page_state
      # debug "Screenshot saved to: #{page.save_screenshot}" if defined?(page) && page.respond_to?(:save_screenshot)
    end
  end
end
