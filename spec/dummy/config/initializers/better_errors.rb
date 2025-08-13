# frozen_string_literal: true

# Better Errors is disabled by default in test and development environments
# This is set automatically in config/environments/*.rb files
# To enable Better Errors in development, you can:
# 1. Remove or comment out ENV['DISABLE_BETTER_ERRORS'] = 'true' in config/environments/development.rb
# 2. Or run with: DISABLE_BETTER_ERRORS=false rails server

if Rails.env.development? && !ENV['DISABLE_BETTER_ERRORS'] && defined?(BetterErrors)
  BetterErrors.application_root = Rails.root
  BetterErrors::Middleware.allow_ip! "0.0.0.0/0"
elsif defined?(BetterErrors)
  # Completely disable Better Errors in test/CI environments
  # Simply try to delete it - if it's not there, it will silently do nothing
  Rails.application.config.middleware.delete BetterErrors::Middleware rescue nil
end