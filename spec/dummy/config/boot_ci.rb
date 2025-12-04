# frozen_string_literal: true

require_relative "boot"

# Avoid autoloading heavy dev-only initializers
Rails.application.configure do
  config.autoloader = :zeitwerk
  config.eager_load = true
end
