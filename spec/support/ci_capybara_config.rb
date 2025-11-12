# frozen_string_literal: true

# CI-specific Capybara/Puma configuration overrides
# This runs after panda-core's capybara_setup.rb

if ENV["GITHUB_ACTIONS"] == "true"
  # Re-register Puma server for CI with single-mode (not cluster)
  # Use 2 threads to avoid blocking when serving page + assets
  #
  # IMPORTANT: Capybara runs the server block in a thread, so we can use
  # the blocking Rack::Handler::Puma.run call safely
  Capybara.register_server :puma do |app, port, host|
    require "rack/handler/puma"
    puts "[CI Config] Starting Puma in single-mode with 2 threads"
    puts "[CI Config] Puma will listen on #{host}:#{port}"

    Rack::Handler::Puma.run(
      app,
      Port: port,
      PreloadApp: false, # Avoids subtle memory-sharing bugs or Rails/Autoload issues in Ruby 3.4/Prism
      Host: host,
      Silent: false, # Enable logging to see what's happening
      Threads: "2:2", # Min:2, Max:2 threads (single-mode, not cluster)
      Verbose: true, # Enable verbose logging,
      Workers: 0 # Explicitly set to single-threaded mode
    )
  end

  # Avoid infinite waits in CI
  Puma::Const::DEFAULTS[:first_data_timeout] = begin
    10
  rescue
    nil
  end

  puts "[CI Config] Puma configured for CI in single-mode with 2 threads"
  puts "[CI Config] Capybara server: #{Capybara.server}"
  puts "[CI Config] Capybara server_host: #{Capybara.server_host}"
end
