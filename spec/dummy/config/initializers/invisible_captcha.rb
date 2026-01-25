# frozen_string_literal: true

# Configure invisible_captcha for test environment
InvisibleCaptcha.setup do |config|
  # Disable honeypots in test environment to avoid interference with tests
  # The custom spam checks (timing, content, rate limiting) are tested directly
  config.honeypots = []

  # Timestamp validation (disabled in favor of our custom timing checks)
  config.timestamp_enabled = false
end
