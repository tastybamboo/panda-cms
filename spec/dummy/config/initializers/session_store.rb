# frozen_string_literal: true

if Rails.env.test?
  require 'rack/session/redis'

  # Use Redis for session storage in tests to avoid cross-process issues with Capybara
  # Both the test process and Capybara's server can read/write to the same Redis instance
  Dummy::Application.config.session_store Rack::Session::Redis,
    redis_server: "redis://localhost:6379/1",
    expire_after: 1.hour,
    key: "_panda_cms_session"
end
