# frozen_string_literal: true

module OmniAuthHelpers
  def login_as_admin
    if ENV["GITHUB_ACTIONS"] == "true"
      puts "\n[CI Debug] Starting admin login process..."
      puts "   Current URL before login: #{page.current_url}"
    end

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "123456789",
      info: {
        email: "admin@example.com",
        name: "Admin User"
      }
    )

    begin
      visit "/auth/google_oauth2"
    rescue => e
      if ENV["GITHUB_ACTIONS"] == "true"
        puts "[CI Debug] Login navigation failed: #{e.message}"
        puts "   Current URL after login error: #{page.current_url}"
        fail "Login failed: #{e.message}"
      else
        raise e
      end
    end

    if ENV["GITHUB_ACTIONS"] == "true"
      puts "[CI Debug] After login navigation:"
      puts "   Current URL: #{page.current_url}"
      puts "   Page title: #{page.title}"
      puts "   Page content length: #{page.html.length}"
      puts "   Page contains admin content: #{page.html.include?("Admin") || page.html.include?("Dashboard")}"

      if page.current_url.include?("about:blank") || page.html.length < 100
        puts "   ❌ Login failed - page didn't load properly"
        puts "   First 200 chars of HTML: #{page.html[0..200]}"
        fail "Login process failed - page didn't load"
      end
    end
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
