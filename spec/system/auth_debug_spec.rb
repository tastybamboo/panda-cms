require "system_helper"

RSpec.describe "Auth Debug", type: :system do
  it "debugs the OAuth flow" do
    # Set up OmniAuth test mode
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "123456",
      info: {
        email: "admin@example.com",
        name: "Admin User"
      },
      credentials: {
        token: "mock_token",
        expires_at: Time.now + 1.week
      }
    })
    
    # Create admin user
    admin_user = Panda::Core::User.find_or_create_by!(email: "admin@example.com") do |user|
      user.firstname = "Admin"
      user.lastname = "User"
      user.admin = true
    end
    
    puts "\n=== STARTING AUTH DEBUG ==="
    puts "Admin user created: #{admin_user.email} (admin: #{admin_user.admin?})"
    puts "OmniAuth test mode: #{OmniAuth.config.test_mode}"
    puts "Mock auth set: #{OmniAuth.config.mock_auth[:google_oauth2].present?}"
    
    # Visit login page
    visit "/admin/login"
    puts "\nLogin page URL: #{page.current_url}"
    puts "Page title: #{page.title}"
    
    # Check if button exists
    has_button = page.has_button?("button-sign-in-google_oauth2")
    puts "Has Google button (by ID): #{has_button}"
    
    # Check for button by text
    has_button_text = page.has_button?("Sign in with Google oauth2")
    puts "Has Google button (by text): #{has_button_text}"
    
    # Print all buttons on page
    all_buttons = page.all('button').map { |b| "#{b[:id]} - #{b.text}" }
    puts "All buttons on page: #{all_buttons.inspect}"
    
    # Check form action
    if page.has_css?('form')
      forms = page.all('form').map { |f| "Action: #{f[:action]}, Method: #{f[:method]}" }
      puts "Forms on page: #{forms.inspect}"
    end
    
    # Try to find and click the button
    if has_button
      puts "\nClicking button by ID..."
      click_button "button-sign-in-google_oauth2"
    elsif has_button_text
      puts "\nClicking button by text..."
      click_button "Sign in with Google oauth2"
    elsif page.has_css?('#button-sign-in-google_oauth2')
      puts "\nClicking element by CSS selector..."
      find('#button-sign-in-google_oauth2').click
    else
      puts "\nNo button found! Page HTML (first 1000 chars):"
      puts page.html[0..1000]
    end
    
    # Wait a moment for redirect
    sleep 1
    
    puts "\n=== AFTER BUTTON CLICK ==="
    puts "Current URL: #{page.current_url}"
    puts "Page title: #{page.title}"
    puts "Page path: #{page.current_path}"
    
    # Check if we're at an error page
    if page.html.include?("error") || page.html.include?("Error")
      puts "Error found in page!"
      puts "Page content (first 500 chars): #{page.text[0..500]}"
    end
    
    # Check if OmniAuth auth is in env
    if defined?(Rails.application.env_config)
      puts "\nRails env config has omniauth.auth: #{Rails.application.env_config['omniauth.auth'].present?}"
    end
    
    # Try direct visit to auth path
    puts "\n=== TRYING DIRECT AUTH PATH ==="
    visit "/admin/auth/google_oauth2"
    sleep 1
    
    puts "After /admin/auth/google_oauth2:"
    puts "  Current URL: #{page.current_url}"
    puts "  Page title: #{page.title}"
    puts "  Page path: #{page.current_path}"
    
    # Check session
    if page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:cookies)
      cookies = page.driver.browser.cookies.all rescue []
      if cookies.respond_to?(:map)
        cookie_info = cookies.map { |c| 
          if c.respond_to?(:name)
            "#{c.name}: #{c.value[0..20] rescue 'N/A'}..."
          else
            c.inspect
          end
        }
        puts "\nCookies: #{cookie_info.inspect}"
      end
    end
    
    puts "=== END AUTH DEBUG ==="
    
    expect(true).to be true
  end
end