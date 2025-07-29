# frozen_string_literal: true

# Disable Better Errors in CI environments
if ENV["CI"] && defined?(BetterErrors)
  BetterErrors.application_root = nil
  Rails.application.config.middleware.delete BetterErrors::Middleware
end