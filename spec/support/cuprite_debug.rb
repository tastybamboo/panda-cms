# frozen_string_literal: true

# Enhanced Cuprite debugging for CI environments
if ENV["RSPEC_DEBUG"] == "true"
  require "capybara/cuprite"

  # Override Cuprite to show more errors
  Capybara.register_driver :cuprite do |app|
    Capybara::Cuprite::Driver.new(
      app,
      window_size: [1200, 800],
      browser_options: {
        "no-sandbox": nil,
        "disable-dev-shm-usage": nil,
        "disable-gpu": nil,
        "disable-software-rasterizer": nil
      },
      inspector: ENV["INSPECTOR"],
      headless: !ENV["INSPECTOR"],
      process_timeout: ENV.fetch("CUPRITE_PROCESS_TIMEOUT", 2).to_i,
      timeout: ENV.fetch("CUPRITE_PROCESS_TIMEOUT", 2).to_i,
      js_errors: true, # Raise on JavaScript errors
      pending_connection_errors: true
    )
  end

  # Log JavaScript console messages
  RSpec.configure do |config|
    config.before(:each, type: :system) do |example|
      if ENV["RSPEC_DEBUG"] == "true"
        puts "\nTEST: #{example.full_description}"
      end
    end

    config.after(:each, type: :system) do |example|
      next unless example.exception && ENV["RSPEC_DEBUG"] == "true"

      # Try to capture browser logs if available
      if page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:console_messages)
        console_logs = page.driver.browser.console_messages
        if console_logs.any?
          puts "\n[Browser Console Logs]:"
          console_logs.each do |log|
            puts "  #{log[:level]}: #{log[:message]}"
          end
        end
      end

      # Try to capture JavaScript errors
      if page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:error_messages)
        js_errors = page.driver.browser.error_messages
        if js_errors.any?
          puts "\n[JavaScript Errors]:"
          js_errors.each do |error|
            puts "  #{error}"
          end
        end
      end
    rescue => e
      puts "\n[Debug Error] Could not capture browser logs: #{e.message}"
    end
  end
end
