# frozen_string_literal: true

# SimpleCov must be loaded before anything else
require "simplecov"
require "simplecov-json"
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
SimpleCov.start

ENV["RAILS_ENV"] ||= "test"

# Act sets ACT=true; drop DATABASE_URL to avoid panda-core's before(:suite) truncation
# hook deadlocking on constraint validation in the act Postgres service.
ENV.delete("DATABASE_URL") if ENV["ACT"] == "true"

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
Panda::Core::Testing::CupriteSetup.setup!

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

  config.use_transactional_fixtures = false

  # Clean DB between tests
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.strategy = (example.metadata[:type] == :system) ? :truncation : :transaction
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.before(:each, type: :system) do
    # Use the cuprite driver from panda-core's CupriteSetup
    # This provides maintained, robust configuration shared across Panda gems
    driven_by :cuprite
  end
end
