# frozen_string_literal: true

# Set OmniAuth test mode and failure condition
OmniAuth.config.test_mode = true
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

module OmniAuthHelpers
  def login_with_google(user)
    if ENV["CI"]
      puts "[Auth Debug] Setting up Google OAuth mock for user: #{user.email}"
    end

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

    if ENV["CI"]
      puts "[Auth Debug] Visiting OAuth callback: /admin/auth/google/callback"
    end

    visit "/admin/auth/google/callback"

    if ENV["CI"]
      puts "[Auth Debug] After OAuth callback - path: #{page.current_path}, content length: #{page.body.length}"
      puts "[Auth Debug] Page title: '#{page.title}'"
    end

    sleep(1.0) # Ensure callback is processed and any redirects complete

    if ENV["CI"]
      puts "[Auth Debug] After sleep - path: #{page.current_path}"
      puts "[Auth Debug] User signed in: #{page.body.include?("Dashboard") || page.current_path.include?("admin")}"
    end
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
    
    if ENV["CI"]
      puts "[DEBUG] About to visit GitHub callback for user: #{user.email}"
      puts "[DEBUG] Current URL before callback: #{current_url}"
      puts "[DEBUG] GitHub enabled: #{Panda::CMS.config.authentication[:github][:enabled]}"
    end
    
    visit "/admin/auth/github/callback"
    
    if ENV["CI"]
      puts "[DEBUG] Current URL after callback: #{current_url}"
      puts "[DEBUG] Page title: #{page.title}"
      
      # Check if we can access basic page properties without DOM queries
      begin
        puts "[DEBUG] Can get page source length: #{page.body.length}"
      rescue => e
        puts "[DEBUG] Failed to get page body: #{e.message}"
      end
      
      # Try a simple browser command first
      begin
        puts "[DEBUG] Browser status: #{page.driver.browser.window_size}"
      rescue => e
        puts "[DEBUG] Browser error: #{e.message}"
      end
      
      # NOW try the problematic DOM query that fails
      begin
        result = page.has_content?('Dashboard')
        puts "[DEBUG] Page has content: #{result}"
      rescue => e
        puts "[DEBUG] DOM query failed: #{e.class}: #{e.message}"
        puts "[DEBUG] Error backtrace: #{e.backtrace[0..3]}"
      end
      
      puts "[DEBUG] Page body preview: #{page.body[0..500]}"
      puts "[DEBUG] All text on page: #{page.all_text[0..1000]}" rescue puts "[DEBUG] Could not get page text"
    end
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

    if ENV["CI"]
      puts "[Auth Debug] Starting admin login for user: #{user.email}"
    end

    login_with_google(user)

    # Try to navigate to admin if not already there
    unless page.current_path == "/admin"
      if ENV["CI"]
        puts "[Auth Debug] Current path: #{page.current_path}, navigating to /admin"
      end

      visit "/admin"

      if ENV["CI"]
        puts "[Auth Debug] After /admin visit - path: #{page.current_path}, content length: #{page.body.length}"
        puts "[Auth Debug] Page title: '#{page.title}'"

        # If we got redirected or have minimal content, there's an auth issue
        if page.current_path != "/admin" || page.body.length < 100
          puts "[Auth Debug] Authentication appears to have failed!"
          puts "[Auth Debug] Current URL: #{page.current_url}"
          puts "[Auth Debug] Page content: #{page.body[0, 200]}"
        end
      end
    end
  end

  def login_as_user(firstname: nil, lastname: nil, email: nil)
    login_with_google(regular_user)
  end

  def admin_user
    # Use fixture user instead of creating new one
    user = Panda::CMS::User.find_by(email: "admin@example.com")
    if user.nil?
      if ENV["CI"]
        puts "[Auth Debug] Admin user not found! Available users:"
        Panda::CMS::User.all.each do |u|
          puts "[Auth Debug]   - #{u.email} (admin: #{u.admin?})"
        end
      end
      raise "Admin user not found in database"
    end

    if ENV["CI"]
      puts "[Auth Debug] Found admin user: #{user.email} (admin: #{user.admin?})"
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
