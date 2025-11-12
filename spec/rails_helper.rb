# frozen_string_literal: true

# SimpleCov must be loaded before anything else
require "simplecov"
require "simplecov-json"
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
SimpleCov.start

ENV["RAILS_ENV"] ||= "test"

require "rubygems"
require "panda/core"
require "panda/core/engine"
require "panda/cms/railtie"

require "rails/all"
require "rails/generators"
require "rails/generators/test_case"
require "propshaft"

# Load dummy app environment BEFORE shared test infrastructure
require File.expand_path("dummy/config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

# Require RSpec/Rails BEFORE shared infrastructure
require "rspec/rails"

# Load shared test infrastructure from panda-core (after dummy app and rspec/rails are loaded)
require "panda/core/testing/rails_helper"

# Ensure Panda::Core models are loaded before CMS support files
Rails.application.eager_load!

# Ensures that the test database schema matches the current schema file.
# Disabled because we use schema.rb and installed migrations via panda_cms:install:migrations
# begin
#   ActiveRecord::Migration.maintain_test_schema!
# rescue ActiveRecord::PendingMigrationError => e
#   abort e.to_s.strip
# end

# Load CMS-specific support files
Dir[Rails.root.join("../support/**/*.rb")].sort.each { |f| require f }

# Ensure Rails.logger is available for request specs
# In some contexts, Rails.logger may be nil, especially in request specs
Rails.logger ||= Logger.new($stdout)
Rails.logger.level = Logger::ERROR

# CMS-specific RSpec configuration
RSpec.configure do |config|
  # Restore ActionController::Base.logger after panda-core sets it to nil
  # invisible_captcha needs a logger to function properly
  config.before(:suite) do
    ActionController::Base.logger = Rails.logger if defined?(ActionController::Base)
  end

  # Include CMS engine route helpers
  config.include Panda::CMS::Engine.routes.url_helpers

  # Configure CMS-specific fixture paths
  config.fixture_paths = [File.expand_path("fixtures", __dir__)]

  # Load CMS fixtures globally EXCEPT those that require users
  # panda_core_users are created programmatically
  # panda_cms_posts require users to exist first
  fixture_files = Dir[File.expand_path("fixtures/*.yml", __dir__)].map do |f|
    File.basename(f, ".yml").to_sym
  end
  fixture_files.delete(:panda_core_users)
  fixture_files.delete(:panda_cms_posts)
  config.global_fixtures = fixture_files unless ENV["SKIP_GLOBAL_FIXTURES"]

  # CMS-specific asset checking in CI
  config.before(:suite) do
    if ENV["GITHUB_ACTIONS"] == "true"
      puts "\n🔍 CI Environment Detected - Checking CMS JavaScript Infrastructure..."

      # Verify compiled assets exist (find any panda-cms assets)
      asset_dir = Rails.root.join("public/panda-cms-assets")
      js_assets = Dir.glob(asset_dir.join("panda-cms-*.js"))
      css_assets = Dir.glob(asset_dir.join("panda-cms-*.css"))

      unless js_assets.any? && css_assets.any?
        puts "❌ CRITICAL: Compiled CMS assets missing!"
        puts "   JavaScript files found: #{js_assets.count}"
        puts "   CSS files found: #{css_assets.count}"
        puts "   Looking in: #{asset_dir}"
        fail "Compiled assets not found - check asset compilation step"
      end

      puts "✅ Compiled CMS assets found:"
      puts "   JavaScript: #{File.basename(js_assets.first)} (#{File.size(js_assets.first)} bytes)"
      puts "   CSS: #{File.basename(css_assets.first)} (#{File.size(css_assets.first)} bytes)"

      # Test basic Rails application responsiveness
      puts "\n🔍 Testing Rails application responsiveness..."
      begin
        require "net/http"
        require "capybara"

        # Try to make a basic HTTP request to test if Rails is responding
        if defined?(Capybara) && Capybara.current_session
          puts "   Capybara server: #{begin
            Capybara.current_session.server.base_url
          rescue
            "not available"
          end}"
        end

        # Check if database is accessible
        if defined?(ActiveRecord::Base)
          begin
            ActiveRecord::Base.connection.execute("SELECT 1")
            puts "   Database connection: ✅ OK"
          rescue => e
            puts "   Database connection: ❌ FAILED - #{e.message}"
          end
        end

        # Check if basic models can be loaded
        begin
          user_count = Panda::Core::User.count
          puts "   User model access: ✅ OK (#{user_count} users)"
        rescue => e
          puts "   User model access: ❌ FAILED - #{e.message}"
        end
      rescue => e
        puts "   Rails app check failed: #{e.message}"
      end
    end
  end
end
