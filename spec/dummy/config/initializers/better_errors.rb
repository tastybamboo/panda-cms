# frozen_string_literal: true

# Only enable Better Errors in development environment
# Disable in test and CI to prevent middleware conflicts
if Rails.env.development? && defined?(BetterErrors)
  BetterErrors.application_root = Rails.root
  BetterErrors::Middleware.allow_ip! "0.0.0.0/0"
elsif defined?(BetterErrors)
  # Prevent Better Errors from being loaded in test/CI
  BetterErrors.application_root = nil
end