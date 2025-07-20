# frozen_string_literal: true

# # Allow multiple threads for Puma
# ENV["RAILS_MAX_THREADS"] = "4"
# ENV["WEB_CONCURRENCY"] = "0"  # Keep workers at 0
# ENV["RAILS_ENV"] = "test"

# Capybara.default_max_wait_time = 5
# Capybara.default_normalize_ws = true

# # Set better_cuprite as both default and JavaScript driver
# Capybara.default_driver = :better_cuprite
# Capybara.javascript_driver = :better_cuprite

# # Configure server
# Capybara.server = :puma
# Capybara.server_host = "127.0.0.1"
# Capybara.server_port = 3001
# Capybara.app_host = "http://#{Capybara.server_host}:#{Capybara.server_port}"

# # Configure Puma with multiple threads
# Capybara.server = lambda do |app, port, host|
#   require "rack/handler/puma"
#   Rack::Handler::Puma.run(
#     app,
#     Host: host,
#     Port: port,
#     Silent: true,
#     Threads: "1:4",  # Allow up to 4 threads
#     workers: 0,
#     persistent_timeout: 20,
#     first_data_timeout: 20,
#     environment: "test"
#   )
# end

# puts "Capybara configured with:"
# puts "  Host: #{Capybara.app_host}"
# puts "  Driver: #{Capybara.default_driver}"
# puts "  JavaScript Driver: #{Capybara.javascript_driver}"
# puts "  Server: Puma (Multi-threaded)"
# puts "  Max Threads: #{ENV["RAILS_MAX_THREADS"]}"
# puts "  Workers: #{ENV["WEB_CONCURRENCY"]}"

# Usually, especially when using Selenium, developers tend to increase the max wait time.
# With Cuprite, there is no need for that.
# We use a Capybara default value here explicitly.
Capybara.default_max_wait_time = 2

# Normalize whitespaces when using `has_text?` and similar matchers,
# i.e., ignore newlines, trailing spaces, etc.
# That makes tests less dependent on slightly UI changes.
Capybara.default_normalize_ws = true

# Where to store system tests artifacts (e.g. screenshots, downloaded files, etc.).
# It could be useful to be able to configure this path from the outside (e.g., on CI).
Capybara.save_path = ENV.fetch("CAPYBARA_ARTIFACTS", "./tmp/capybara")

# Disable animation so we're not waiting for it
Capybara.disable_animation = true

# See BetterRailsSystemTests#take_screenshot
Capybara.singleton_class.prepend(Module.new do
  attr_accessor :last_used_session

  def using_session(name, &block)
    self.last_used_session = name
    super
  ensure
    self.last_used_session = nil
  end
end)

Capybara.server_host = "127.0.0.1"
Capybara.server_port = 3002

RSpec.configure do |config|
  # Temporarily disable aggressive session reset to fix test isolation issues
  # config.before(:each, type: :system) do
  #   Capybara.reset_sessions!
  #   page.driver.reset!
  # end

  # Reset only after each test instead of before
  config.after(:each, type: :system) do
    Capybara.reset_sessions! if example.exception
    page.driver.reset! if example.exception
  end
end

Panda::CMS.config.url = Capybara.app_host
Rails.application.routes.default_url_options[:host] = Capybara.app_host
