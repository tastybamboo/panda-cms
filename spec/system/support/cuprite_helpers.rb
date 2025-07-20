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
  "enable-features": "NetworkService,NetworkServiceInProcess"
}

# Add CI-specific browser options for better stability
if ENV['CI']
  browser_options.merge!({
    "disable-background-timer-throttling": nil,
    "disable-renderer-backgrounding": nil,
    "disable-backgrounding-occluded-windows": nil,
    "disable-features": "TranslateUI,VizDisplayCompositor",
    "no-zygote": nil,
    "single-process": nil,
    "disable-ipc-flooding-protection": nil
  })
end

@cuprite_options = {
  window_size: [1440, 1000],
  browser_options: browser_options,
  process_timeout: ENV['CI'] ? 180 : 120,
  timeout: ENV['CI'] ? 60 : 30,
  inspector: ENV["DEBUG"].in?(%w[y 1 yes true]),
  logger: (ENV["DEBUG"].in?(%w[y 1 yes true]) || ENV['CI']) ? FerrumLogger.new : StringIO.new,
  slowmo: ENV.fetch("SLOWMO", 0).to_f,
  js_errors: true,
  headless: !ENV["HEADLESS"].in?(%w[n 0 no false]),
  pending_connection_errors: false
}

Capybara.register_driver(:better_cuprite) do |app|
  if ENV['CI']
    Rails.logger.debug "[Cuprite Debug] Initializing browser with CI-specific options"
    Rails.logger.debug "[Cuprite Debug] Process timeout: #{@cuprite_options[:process_timeout]}"
    Rails.logger.debug "[Cuprite Debug] Timeout: #{@cuprite_options[:timeout]}"
  end

  Capybara::Cuprite::Driver.new(app, **@cuprite_options)
end

# Configure Capybara to use :better_cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :better_cuprite

RSpec.configure do |config|
  config.include CupriteHelpers, type: :system
end
