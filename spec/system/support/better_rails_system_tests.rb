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
        # Use Capybara's save_screenshot method
        screenshot_path = Capybara.save_screenshot
        puts "Screenshot saved to: #{screenshot_path}" if screenshot_path
      rescue => e
        puts "Failed to capture screenshot: #{e.message}"
      end
    end
  end
end
