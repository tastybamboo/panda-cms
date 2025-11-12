# frozen_string_literal: true

# CI-specific Capybara/Puma configuration overrides
# This runs after panda-core's capybara_setup.rb

if ENV["GITHUB_ACTIONS"] == "true"
  # Re-register Puma server with more concurrency for CI
  # Use 2 threads to avoid blocking when serving page + assets
  Capybara.register_server :puma do |app, port, host|
    require "rack/handler/puma"
    puts "[CI Config] Configuring Puma with 2 threads for CI environment"
    Rack::Handler::Puma.run(
      app,
      Port: port,
      Host: host,
      Silent: false, # Enable logging to see what's happening
      Threads: "2:2", # Min:2, Max:2 threads
      workers: 0 # 0 workers = single process mode (workers create separate processes)
    )
  end

  puts "[CI Config] Puma configured for CI with 2 threads"
  puts "[CI Config] Capybara server: #{Capybara.server}"
  puts "[CI Config] Capybara server_host: #{Capybara.server_host}"
end
