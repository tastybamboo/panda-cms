# frozen_string_literal: true

# Local/CI Cuprite driver tuned for containers.
# Ferrum can take longer to boot Chrome in nested Docker (act) and needs no-sandbox flags.
return unless defined?(Capybara)

require "capybara/cuprite"

Capybara.default_max_wait_time = 5

def panda_cuprite_options(window_size:)
  browser_path = ENV["BROWSER_PATH"]
  browser_path ||= ["/usr/bin/chromium", "/usr/bin/chromium-browser", "/usr/bin/google-chrome"].find { |path| File.exist?(path) }

  {
    window_size: window_size,
    headless: ENV.fetch("HEADFUL", "false") != "true",
    timeout: ENV.fetch("CUPRITE_TIMEOUT", "30").to_i,
    process_timeout: ENV.fetch("CUPRITE_PROCESS_TIMEOUT", "120").to_i,
    browser_path: browser_path,
    browser_options: {
      "no-sandbox": nil,
      "disable-setuid-sandbox": nil,
      "disable-dev-shm-usage": nil,
      "disable-gpu": nil,
      "remote-debugging-port": "0"
    }
  }
end

Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app, **panda_cuprite_options(window_size: [1440, 1000]))
end

Capybara.register_driver :cuprite_mobile do |app|
  Capybara::Cuprite::Driver.new(app, **panda_cuprite_options(window_size: [375, 667]))
end

Capybara.javascript_driver = :cuprite
Capybara.default_driver = :rack_test

# Ensure default server is Puma (not panda-core's :puma_ci proc).
Capybara.server = :puma

# Prefer dynamic ports to avoid EADDRINUSE when servers linger between examples.
RSpec.configure do |config|
  config.append_before(:suite) do
    Capybara.server = :puma
    Capybara.server_host = "127.0.0.1"
    Capybara.server_port = nil # let Capybara choose an available port
    Capybara.app_host = nil
    Capybara.always_include_port = false
    Capybara.reuse_server = true

    puts "[Cuprite Override] Capybara.server      = #{Capybara.server.inspect}"
    puts "[Cuprite Override] Capybara.app_host    = #{Capybara.app_host.inspect}"
    puts "[Cuprite Override] Capybara.server_host = #{Capybara.server_host.inspect}"
    puts "[Cuprite Override] Capybara.server_port = #{Capybara.server_port.inspect}"
  end
end
