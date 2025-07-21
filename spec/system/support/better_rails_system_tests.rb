# frozen_string_literal: true

# Extends Rails system tests with improved screenshot and driver handling
#
# This module provides enhancements to Rails system tests:
# - Configures system tests to use Cuprite by default
# - Sets up proper URL host handling for system tests
# - Ensures screenshots are captured on test failures
#
# @example Using in a system test
#   describe "My Feature", type: :system do
#     it "does something" do
#       visit root_path
#       # Test will automatically use Cuprite driver
#       # Screenshots will be captured properly on failure
#     end
#   end
module BetterRailsSystemTests
  # Make failure screenshots compatible with multi-session setup.
  # That's where we use Capybara.last_used_session introduced before.
  def take_screenshot
    return super unless Capybara.last_used_session

    Capybara.using_session(Capybara.last_used_session) { super }
  end
end

RSpec.configure do |config|
  config.include BetterRailsSystemTests, type: :system

  # Make urls in mailers contain the correct server host.
  # This is required for testing links in emails (e.g., via capybara-email).
  config.around(:each, type: :system) do |ex|
    was_host = Rails.application.default_url_options[:host]
    Rails.application.default_url_options[:host] = Capybara.server_host
    ex.run
    Rails.application.default_url_options[:host] = was_host
  end

  # Make sure this hook runs before others
  # Means you don't have to set js: true in every system spec
  config.prepend_before(:each, type: :system) do
    driven_by :better_cuprite
    # Don't load seeds when using fixtures to avoid conflicts
    # Rails.application.load_seed
  end

  # Set up Current attributes after Capybara is ready
  config.before(:each, type: :system) do
    # Wait for Capybara to be ready and set Current.root properly
    if Capybara.current_session.server
      host = Capybara.current_session.server.host
      port = Capybara.current_session.server.port
      Panda::CMS::Current.root = "http://#{host}:#{port}"
    else
      # Fallback if server isn't available yet
      Panda::CMS::Current.root = "http://127.0.0.1:3001"
    end

    # Set other Current attributes that might be needed
    Panda::CMS::Current.request_id = SecureRandom.uuid
    Panda::CMS::Current.user_agent = "Test User Agent"
    Panda::CMS::Current.ip_address = "127.0.0.1"
    Panda::CMS::Current.page = nil
    Panda::CMS::Current.user = nil

    # Ensure templates have blocks generated if using fixtures
    if defined?(Panda::CMS::Template) && Panda::CMS::Template.respond_to?(:generate_missing_blocks)
      Panda::CMS::Template.generate_missing_blocks
    end
  end

  # Enable automatic screenshots on failure
  config.after(:each, type: :system) do |example|
    if example.exception
      begin
        # Wait for any pending JavaScript and network requests to complete
        if page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:network)
          begin
            page.driver.browser.network.wait_for_idle(timeout: 2)
          rescue
            nil
          end
        end

        # Wait for DOM to be ready
        sleep 0.5

        # Get comprehensive page info
        page_html = begin
          page.html
        rescue
          "<html><body>Error loading page</body></html>"
        end
        begin
          page.current_url
        rescue
          "unknown"
        end
        begin
          page.current_path
        rescue
          "unknown"
        end
        page_title = begin
          page.title
        rescue
          "N/A"
        end

        # Check for specific error indicators
        if page_html.include?("error") || page_html.include?("exception") || page_html.include?("404") || page_html.include?("500")
          # Error page detected
        end

        # Check for redirect or blank page indicators
        if page_html.length < 100
          puts "Warning: Page content appears minimal (#{page_html.length} chars) when taking screenshot"
          if ENV["CI"]
            puts "CI Debug - Current URL: #{page.current_url rescue 'unknown'}"
            puts "CI Debug - Page status: #{page.status_code rescue 'unknown'}"
            puts "CI Debug - Page HTML content: '#{page_html[0, 200]}'"
            puts "CI Debug - Capybara server host: #{Capybara.server_host}"
            puts "CI Debug - Capybara server port: #{Capybara.server_port}"
          end
        end

        # Check session state
        if page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:cookies)
          cookies = begin
            page.driver.browser.cookies.all
          rescue
            []
          end
          begin
            cookies.find { |cookie| cookie["name"].include?("session") }
          rescue
            nil
          end
        end

        # Use Capybara's save_screenshot method
        screenshot_path = Capybara.save_screenshot
        if screenshot_path
          puts "Screenshot saved to: #{screenshot_path}"
          puts "Page title: #{page_title}"
          puts "Page content length: #{page_html.length} characters"

          # Save page HTML for debugging in CI
          if ENV["GITHUB_ACTIONS"]
            html_debug_path = screenshot_path.gsub(".png", ".html")
            File.write(html_debug_path, page_html)
            puts "Page HTML saved to: #{html_debug_path}"
          end
        end
      rescue => e
        puts "Failed to capture screenshot: #{e.message}"
        puts "Exception class: #{example.exception.class}"
        puts "Exception message: #{example.exception.message}"
      end
    end
  end
end
