# frozen_string_literal: true

require "ferrum"
require "capybara/cuprite"
require_relative "cuprite_helper_methods"

# Configure Cuprite options
cuprite_options = {
  window_size: [1440, 1000],
  inspector: ENV["INSPECTOR"].in?(%w[y 1 yes true]),
  headless: !ENV["HEADLESS"].in?(%w[n 0 no false]),
  slowmo: ENV["SLOWMO"]&.to_f || 0,
  timeout: 30,
  js_errors: false,
  ignore_default_browser_options: false,
  process_timeout: 10,
  wait_for_network_idle: false,  # Don't wait for all network requests
  pending_connection_errors: false,  # Don't fail on pending external connections
  browser_options: {
    "no-sandbox": nil,
    "disable-gpu": nil,
    "disable-dev-shm-usage": nil,
    "disable-background-networking": nil,
    "disable-default-apps": nil,
    "disable-extensions": nil,
    "disable-sync": nil,
    "disable-translate": nil,
    "no-first-run": nil,
    "ignore-certificate-errors": nil,
    "allow-insecure-localhost": nil,
    "enable-features": "NetworkService,NetworkServiceInProcess",
    "disable-blink-features": "AutomationControlled"
  }
}

# Add more permissive options in CI
if ENV["GITHUB_ACTIONS"] == "true"
  cuprite_options[:browser_options].merge!({
    "disable-web-security": nil,
    "allow-file-access-from-files": nil,
    "allow-file-access": nil
  })

  puts "\n🔍 Cuprite Configuration:"
  puts "   Debug mode: #{ENV["DEBUG"]}"
  puts "   Headless: #{cuprite_options[:headless]}"
  puts "   Browser options: #{cuprite_options[:browser_options].keys.join(" --")}"
  puts ""
end

Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app, **cuprite_options)
end

# Configure Capybara
Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite

# Include helper methods
RSpec.configure do |config|
  config.include CupriteHelpers, type: :system
end