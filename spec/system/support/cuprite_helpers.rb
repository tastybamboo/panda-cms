# frozen_string_literal: true

# First, load Cuprite Capybara integration
require "capybara/cuprite"
require_relative "ferrum_logger"
require_relative "cuprite_helper_methods"

@cuprite_options = {
  window_size: [1440, 1000],
  browser_options: {
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
  },
  process_timeout: 120,
  timeout: 30,
  inspector: ENV["DEBUG"].in?(%w[y 1 yes true]),
  logger: ENV["DEBUG"].in?(%w[y 1 yes true]) ? FerrumLogger.new : StringIO.new,
  slowmo: ENV.fetch("SLOWMO", 0).to_f,
  js_errors: true,
  headless: !ENV["HEADLESS"].in?(%w[n 0 no false]),
  pending_connection_errors: false
}

Capybara.register_driver(:better_cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, **@cuprite_options)
end

# Configure Capybara to use :better_cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :better_cuprite

puts "[DEBUG] Registering Cuprite with options: #{@cuprite_options.inspect}" if ENV["BROWSER_DEBUG"]

RSpec.configure do |config|
  config.include CupriteHelpers, type: :system
end
