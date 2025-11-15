# frozen_string_literal: true

# Configure invisible_captcha for test environment
InvisibleCaptcha.setup do |config|
  # Honeypot field names
  config.honeypots = %w[spinner subtitle]

  # Timestamp validation (disabled in favor of our custom timing checks)
  config.timestamp_enabled = false
end
