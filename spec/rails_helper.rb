# frozen_string_literal: true

require "rubygems"
require "panda/core"
require "panda/cms/railtie"

require "rails/all"
require "rails/generators"
require "rails/generators/test_case"

require "simplecov"
require "simplecov-json"
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
SimpleCov.start

require "propshaft"
require "stimulus-rails"
require "turbo-rails"

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("dummy/config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

# Add additional requires below this line. Rails is not loaded until this point!
require "database_cleaner/active_record"
require "shoulda/matchers"
require "capybara"
require "capybara/rspec"
require "view_component/test_helpers"
require "puma"

# Ensures that the test database schema matches the current schema file.
# If there are pending migrations it will invoke `db:test:prepare` to
# recreate the test database by loading the schema.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# Load support files first
Dir[Rails.root.join("../support/**/*.rb")].sort.each { |f| require f }

# Configure fixtures
ActiveRecord::FixtureSet.context_class.send :include, ActiveSupport::Testing::TimeHelpers

# Configure fixture set class name mapping for namespaced models
# This tells Rails which model class to use for each fixture file
module PandaCmsFixtures
  def self.get_class_name(fixture_set_name)
    case fixture_set_name
    when "panda_cms_users" then "Panda::CMS::User"
    when "panda_cms_posts" then "Panda::CMS::Post"
    when "panda_cms_pages" then "Panda::CMS::Page"
    when "panda_cms_templates" then "Panda::CMS::Template"
    when "panda_cms_blocks" then "Panda::CMS::Block"
    when "panda_cms_block_contents" then "Panda::CMS::BlockContent"
    when "panda_cms_menus" then "Panda::CMS::Menu"
    when "panda_cms_menu_items" then "Panda::CMS::MenuItem"
    end
  end
end

# Override ActiveRecord::FixtureSet to use our mapping
module ActiveRecord
  class FixtureSet
    alias_method :original_model_class, :model_class

    def model_class
      if (klass = PandaCmsFixtures.get_class_name(@name))
        klass.constantize
      else
        original_model_class
      end
    end
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  # URL helpers in tests would be nice to use
  config.include Rails.application.routes.url_helpers
  config.include Panda::CMS::Engine.routes.url_helpers

  config.include ViewComponent::TestHelpers, type: :view_component
  config.include Capybara::RSpecMatchers, type: :view_component

  # Use transactions, so we don't have to worry about cleaning up the database
  # The idea is to start each example with a clean database, create whatever data
  # is necessary for that example, and then remove that data by simply rolling
  # back the transaction at the end of the example.
  # NB: If you use before(:context), you must use after(:context) too
  # Normally, use before(:each) and after(:each)
  config.use_transactional_fixtures = true

  # Infer an example group's spec type from the file location.
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails and gems in backtraces.
  config.filter_rails_from_backtrace!
  # add, if needed: config.filter_gems_from_backtrace("gem name")

  # Allow using focus keywords "f... before a specific test"
  config.filter_run_when_matching :focus

  # Exclude EditorJS tests by default unless specifically requested
  config.filter_run_excluding :editorjs unless ENV["INCLUDE_EDITORJS"] == "true"

  # Log examples to allow using --only-failures and --next-failure
  config.example_status_persistence_file_path = "spec/examples.txt"

  # https://rspec.info/features/3-12/rspec-core/configuration/zero-monkey-patching-mode/
  config.disable_monkey_patching!

  # Use verbose output if only running one spec file
  config.default_formatter = "doc" if config.files_to_run.one?

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run: --seed 1234
  Kernel.srand config.seed
  config.order = :random

  # Use specific formatter for GitHub Actions
  RSpec.configure do |config|
    # Use the GitHub Annotations formatter for CI
    if ENV["GITHUB_ACTIONS"] == "true"
      require "rspec/github"
      config.add_formatter RSpec::Github::Formatter
    end
  end

  # Configure fixtures path and enable fixtures
  config.fixture_paths = [File.expand_path("fixtures", __dir__)]
  config.use_transactional_fixtures = true
  # Load fixtures globally for all tests
  config.global_fixtures = :all

  if defined?(Bullet) && Bullet.enable?
    config.before(:each) do
      Bullet.start_request
    end

    config.after(:each) do
      Bullet.perform_out_of_channel_notifications if Bullet.notification?
      Bullet.end_request
    end
  end

  OmniAuth.config.test_mode = true

  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
  end
end
