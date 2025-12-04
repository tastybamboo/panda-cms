# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

if ENV["CI"] == "1"
  require_relative "boot_ci"
  return
end

begin
  require 'bootsnap/setup'
rescue LoadError
  # Bootsnap is optional - skip if not available
end
require 'rails/all'     # Add this line to ensure all Rails frameworks are loaded
