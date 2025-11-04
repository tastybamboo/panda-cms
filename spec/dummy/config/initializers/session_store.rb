# frozen_string_literal: true

if Rails.env.test?
  require 'rack/session/redis'

  # Monkey-patch for compatibility with newer Redis gem
  # The Redis gem no longer has .connect as a class method
  module Rack
    module Session
      class Redis < Abstract::ID
        class MarshalledRedis < ::Redis
          def self.connect(options = {})
            new(options)
          end
        end
      end
    end
  end

  # Use Redis for session storage in tests to avoid cross-process issues with Capybara
  # Both the test process and Capybara's server can read/write to the same Redis instance
  Dummy::Application.config.session_store Rack::Session::Redis,
    url: "redis://localhost:6379/1",
    namespace: "rack:session:panda_cms",
    expire_after: 1.hour,
    key: "_panda_cms_session"
end
