# frozen_string_literal: true

# First, load Cuprite Capybara integration
require "capybara/cuprite"
require_relative "ferrum_logger"
require_relative "cuprite_helper_methods"

# Enhanced browser options for CI environment
browser_options = {
  "no-sandbox": nil,
  "disable-gpu": nil,
  "disable-dev-shm-usage": nil,
  "disable-background-networking": nil,
  "disable-default-apps": nil,
  "disable-extensions": nil,
  "disable-sync": nil,
  "disable-translate": nil,
  "disable-web-security": nil,
  "no-first-run": nil,
  "ignore-certificate-errors": nil,
  "allow-insecure-localhost": nil,
  "enable-features": "NetworkService,NetworkServiceInProcess",
  # Additional flags to allow JavaScript execution in CI
  "disable-blink-features": "AutomationControlled",
  "disable-site-isolation-trials": nil,
  "allow-running-insecure-content": nil,
  "disable-features": "IsolateOrigins,site-per-process"
}

# Add more permissive options in CI to debug JavaScript issues
if ENV["GITHUB_ACTIONS"] == "true"
  browser_options.merge!({
    "unsafely-treat-insecure-origin-as-secure": "http://127.0.0.1,http://localhost",
    "disable-web-security": nil,
    "allow-file-access-from-files": nil,
    "allow-file-access": nil
  })
end


@cuprite_options = {
  window_size: [1440, 1000],
  browser_options: browser_options,
  process_timeout: 30,
  timeout: 15,
  inspector: ENV["DEBUG"].in?(%w[y 1 yes true]),
  logger: ENV["DEBUG"].in?(%w[y 1 yes true]) ? FerrumLogger.new : StringIO.new,
  slowmo: ENV.fetch("SLOWMO", 0).to_f,
  js_errors: true,
  headless: !ENV["HEADLESS"].in?(%w[n 0 no false]),
  pending_connection_errors: false
}

# Log browser configuration in CI
if ENV["GITHUB_ACTIONS"] == "true"
  puts "\n🔍 Ferrum/Cuprite Browser Configuration:"
  puts "   Debug mode: #{ENV["DEBUG"]}"
  puts "   Headless: #{@cuprite_options[:headless]}"
  puts "   JS errors tracking: #{@cuprite_options[:js_errors]}"
  puts "   Browser options:"
  browser_options.each do |key, value|
    puts "     #{key}: #{value.nil? ? 'enabled' : value}"
  end
  puts ""
end

Capybara.register_driver(:better_cuprite) do |app|
  driver = Capybara::Cuprite::Driver.new(app, **@cuprite_options)
  
  # Add page load event handling to ensure browser doesn't reset
  if ENV["GITHUB_ACTIONS"] == "true"
    # Override the visit method to handle about:blank issues
    driver.define_singleton_method :visit_with_retry do |url|
      retries = 0
      begin
        visit_without_retry(url)
        # Wait for page to load
        browser.network.wait_for_idle(timeout: 5) rescue nil
      rescue => e
        retries += 1
        if retries <= 3 && current_url.include?('about:blank')
          puts "[CI] Browser reset detected on visit, retry #{retries}/3"
          sleep 1
          retry
        else
          raise e
        end
      end
    end
    
    driver.singleton_class.send(:alias_method, :visit_without_retry, :visit)
    driver.singleton_class.send(:alias_method, :visit, :visit_with_retry)
  end
  
  driver
end

# Configure Capybara to use :better_cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :better_cuprite

RSpec.configure do |config|
  config.include CupriteHelpers, type: :system
end
