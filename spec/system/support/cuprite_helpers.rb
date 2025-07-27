# frozen_string_literal: true

require "selenium-webdriver"
require_relative "cuprite_helper_methods"

# Configure Chrome options for Selenium
chrome_options = Selenium::WebDriver::Chrome::Options.new
chrome_options.add_argument("--headless") unless ENV["HEADLESS"].in?(%w[n 0 no false])
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--disable-dev-shm-usage")
chrome_options.add_argument("--disable-background-networking")
chrome_options.add_argument("--disable-default-apps")
chrome_options.add_argument("--disable-extensions")
chrome_options.add_argument("--disable-sync")
chrome_options.add_argument("--disable-translate")
chrome_options.add_argument("--no-first-run")
chrome_options.add_argument("--ignore-certificate-errors")
chrome_options.add_argument("--allow-insecure-localhost")
chrome_options.add_argument("--enable-features=NetworkService,NetworkServiceInProcess")
chrome_options.add_argument("--disable-blink-features=AutomationControlled")
chrome_options.add_argument("--disable-site-isolation-trials")
chrome_options.add_argument("--allow-running-insecure-content")
chrome_options.add_argument("--disable-features=IsolateOrigins,site-per-process")
chrome_options.add_argument("--window-size=1440,1000")

# Add more permissive options in CI
if ENV["GITHUB_ACTIONS"] == "true"
  chrome_options.add_argument("--disable-web-security")
  chrome_options.add_argument("--allow-file-access-from-files")
  chrome_options.add_argument("--allow-file-access")

  puts "\n🔍 Selenium Chrome Configuration:"
  puts "   Debug mode: #{ENV["DEBUG"]}"
  puts "   Headless: #{!ENV["HEADLESS"].in?(%w[n 0 no false])}"
  puts "   Browser options: #{chrome_options.args.join(" ")}"
  puts ""
end

Capybara.register_driver :selenium_chrome do |app|
  # Enable browser console logging
  chrome_options.add_preference("goog:loggingPrefs", {browser: "ALL"})

  options = {
    browser: :chrome,
    options: chrome_options
  }

  # Add logging in debug mode
  if ENV["DEBUG"].in?(%w[y 1 yes true])
    options[:service] = Selenium::WebDriver::Service.chrome(
      args: ["--verbose", "--log-path=#{Rails.root.join("log", "chromedriver.log")}"]
    )
  end

  Capybara::Selenium::Driver.new(app, **options)
end

# Configure Capybara
Capybara.default_driver = :selenium_chrome
Capybara.javascript_driver = :selenium_chrome
Capybara.default_max_wait_time = 10
Capybara.server = :puma, {Silent: true}

# Include the same helper methods from Cuprite
RSpec.configure do |config|
  config.include CupriteHelpers, type: :system
end
