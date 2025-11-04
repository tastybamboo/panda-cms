# frozen_string_literal: true

if Rails.env.test?
  require 'rack/session/redis'
  require 'redis'

  # Use Redis for session storage in tests to avoid cross-process issues with Capybara
  # Both the test process and Capybara's server can read/write to the same Redis instance
  redis_client = Redis.new(url: "redis://localhost:6379/1")

  Dummy::Application.config.session_store Rack::Session::Redis,
    redis_client: redis_client,
    expire_after: 1.hour,
    key: "_panda_cms_session"
end
