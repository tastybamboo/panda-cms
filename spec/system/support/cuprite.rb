# frozen_string_literal: true

# Local/CI Cuprite driver tuned for containers.
# Ferrum can take longer to boot Chrome in nested Docker (act) and needs no-sandbox flags.
return unless defined?(Capybara)

require "capybara/cuprite"

Capybara.default_max_wait_time = 5

def panda_cuprite_options(window_size:)
  browser_path = ENV["BROWSER_PATH"]
  browser_path ||= ["/usr/bin/chromium", "/usr/bin/chromium-browser", "/usr/bin/google-chrome"].find { |path| File.exist?(path) }

  panda_core = Gem.loaded_specs["panda-core"]
  puts "[Cuprite Override] panda-core version: #{panda_core&.version} path: #{panda_core&.full_gem_path}"

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
      "remote-debugging-port": "0",
      "js-errors": true,
      flatten: false,
      logger: $stdout
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
Capybara.app ||= Rack::Builder.new { run Rails.application }

# Prefer dynamic ports to avoid EADDRINUSE when servers linger between examples.
RSpec.configure do |config|
  config.append_before(:suite) do
    Capybara.server = ENV.fetch("CAPYBARA_SERVER", "puma").to_sym
    Capybara.server_host = ENV.fetch("CAPYBARA_SERVER_HOST", "0.0.0.0")
    Capybara.server_port = nil # let Capybara choose an available port
    Capybara.app_host = nil # set after we know the chosen port
    Capybara.always_include_port = true
    Capybara.reuse_server = true

    puts "[Cuprite Override] Capybara.server      = #{Capybara.server.inspect}"
    puts "[Cuprite Override] Capybara.app_host    = #{Capybara.app_host.inspect}"
    puts "[Cuprite Override] Capybara.server_host = #{Capybara.server_host.inspect}"
    puts "[Cuprite Override] Capybara.server_port = #{Capybara.server_port.inspect}"

    # Force the app server to boot and log the first response to catch startup failures.
    begin
      server = Capybara::Server.new(Capybara.app, Capybara.server_port, Capybara.server_host, &Capybara.servers[Capybara.server])
      server.boot
      server_port = server&.port
      raise "Capybara server did not start" unless server_port
      resolved_app_host = ENV["CAPYBARA_APP_HOST"] || "http://127.0.0.1:#{server_port}"
      Capybara.app_host = resolved_app_host
      puts "[Cuprite Override] Resolved app_host  = #{Capybara.app_host.inspect}"
      puts "[Cuprite Override] Resolved server    = #{server.host}:#{server_port}"

      warmup_url = "#{resolved_app_host}/admin/login"
      session = Capybara::Session.new(:cuprite)
      session.visit(warmup_url)
      puts "[Cuprite Override] Cuprite warmup GET #{warmup_url} -> status #{session.status_code}"
    rescue => e
      warn "[Cuprite Override] Cuprite warmup failed: #{e.class}: #{e.message}"
      e.backtrace.first(5).each { |line| warn line }
    end
  end
end
