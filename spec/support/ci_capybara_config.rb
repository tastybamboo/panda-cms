# frozen_string_literal: true

# CI-specific Capybara/Puma configuration overrides
# This file is only relevant for system tests.
#
# It MUST NOT run for model/request/unit specs, because those don't need
# a Capybara server and shouldn't try to configure Puma.

return unless defined?(Capybara)

# Only bother with this in CI or when explicitly enabled
ci_mode = ENV["GITHUB_ACTIONS"] == "true" || ENV["CI_SYSTEM_SPECS"] == "true"
return unless ci_mode

require "rack/handler/puma"

RSpec.configure do |config|
  # Only apply this to system specs
  config.before(:suite, type: :system) do
    Capybara.server = :puma_ci

    # Make Capybara a little more patient for server boot/JS
    Capybara.default_max_wait_time = Integer(ENV.fetch("CAPYBARA_MAX_WAIT_TIME", 5))

    # Keep things predictable in CI
    Capybara.server_host = "127.0.0.1"
    Capybara.always_include_port = true

    puts "[CI Config] Capybara.server      = #{Capybara.server.inspect}"
    puts "[CI Config] Capybara.server_host = #{Capybara.server_host.inspect}"
    puts "[CI Config] Capybara.max_wait    = #{Capybara.default_max_wait_time}s"
  end
end

# Single-mode Puma server for Capybara (no workers, no fork)
Capybara.register_server :puma_ci do |app, port, host|
  puts "[CI Config] Starting Puma (single mode) on #{host}:#{port}"

  # Read threads from ENV if you want to tweak; defaults to 2:2
  min_threads = Integer(ENV.fetch("PUMA_MIN_THREADS", "2"))
  max_threads = Integer(ENV.fetch("PUMA_MAX_THREADS", "2"))

  options = {
    Host: host,
    Port: port,
    Threads: "#{min_threads}:#{max_threads}",
    Workers: 0,          # <-- NO CLUSTER / NO FORK
    Silent: false,       # show logs in CI
    Verbose: true,
    PreloadApp: false    # safer with Ruby 3.4 / Prism
  }

  Rack::Handler::Puma.run(app, options)
end
