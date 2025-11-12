# frozen_string_literal: true

# CI-specific Capybara/Puma configuration overrides
# This runs after panda-core's capybara_setup.rb

if ENV["GITHUB_ACTIONS"] == "true"
  # Re-register Puma server with more concurrency for CI
  # Use 2 threads to avoid blocking when serving page + assets
  #
  # IMPORTANT: Capybara runs the server block in a thread, so we can use
  # the blocking Rack::Handler::Puma.run call safely
  Capybara.register_server :puma do |app, port, host|
    require "rack/handler/puma"
    puts "[CI Config] Starting Puma with 2 threads for CI environment"
    puts "[CI Config] Puma will listen on #{host}:#{port}"

    Rack::Handler::Puma.run(
      app,
      Port: port,
      Host: host,
      Silent: false, # Enable logging to see what's happening
      Threads: "2:2", # Min:2, Max:2 threads
      workers: 0, # 0 workers = single process mode
      Verbose: true # Enable verbose logging
    )
  end

  puts "[CI Config] Puma server configured for CI with 2 threads"
  puts "[CI Config] Capybara server: #{Capybara.server}"
  puts "[CI Config] Capybara server_host: #{Capybara.server_host}"
end
