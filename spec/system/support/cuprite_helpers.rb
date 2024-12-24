class FerrumLogger
  def puts(log_str)
    _log_symbol, _log_time, log_body_str = log_str.strip.split(" ", 3)
    return if log_body_str.nil?

    begin
      log_body = JSON.parse(log_body_str)
    rescue
      puts log_body_str
      return
    end

    case log_body["method"]
    when "Runtime.consoleAPICalled"
      log_body["params"]["args"].each do |arg|
        case arg["type"]
        when "string"
          Kernel.puts arg["value"]
        when "object"
          Kernel.puts arg["preview"]["properties"].map { |x| [x["name"], x["value"]] }.to_h
        end
      end

    when "Runtime.exceptionThrown"
      # noop, this is already logged because we have "js_errors: true" in cuprite.

    when "Log.entryAdded"
      Kernel.puts "#{log_body["params"]["entry"]["url"]} - #{log_body["params"]["entry"]["text"]}"
    end
  end
end

# RSpec.configure do |config|
#   config.before(:each, type: :system) do
#     page.driver.browser.options.logger.page = page.driver.browser.page
#   end
# end

# First, load Cuprite Capybara integration
require "capybara/cuprite"

@cuprite_options = {
  window_size: [1440, 800],
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
    "no-first-run": nil
  },
  process_timeout: 60,
  timeout: 30,
  inspector: ENV["DEBUG"].in?(%w[y 1 yes true]),
  logger: FerrumLogger.new,
  slowmo: ENV.fetch("SLOWMO", 0).to_f,
  js_errors: true,
  headless: !ENV["HEADLESS"].in?(%w[n 0 no false]),
  pending_connection_errors: false
}

if ENV["DEBUG"] == "1"
  puts "Registering Cuprite with options: #{@cuprite_options.inspect}"
end

Capybara.register_driver(:better_cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, **@cuprite_options)
end

# Configure Capybara to use :better_cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :better_cuprite

module CupriteHelpers
  def debug(message)
    puts "[DEBUG] #{message}" if ENV["DEBUG"]
  end

  # Drop #pause anywhere in a test to stop the execution.
  # Useful when you want to checkout the contents of a web page in the middle of a test
  # running in a headful mode.
  def pause
    page.driver.pause
  end

  # Drop #browser_debug anywhere in a test to open a Chrome inspector and pause the execution
  # Usage: browser_debug(binding)
  def browser_debug(*)
    page.driver.debug(*)
  end

  # Allows sending a list of CSS selectors to be clicked on in the correct order (no delay)
  # Useful where you need to trigger e.g. a blur event on an input field
  def click_on_selectors(*css_selectors)
    css_selectors.each do |selector|
      page.driver.browser.at_css(selector).click
    end
  end
end

RSpec.configure do |config|
  config.include CupriteHelpers, type: :system
end
