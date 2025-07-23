# frozen_string_literal: true

require "silencer/rails/logger"

# Don't log requests to the healthcheck endpoint
Rails.application.configure do
  config.middleware.swap(
    Rails::Rack::Logger,
    Silencer::Logger,
    config.log_tags,
    silence: ["/up"]
  )
end
