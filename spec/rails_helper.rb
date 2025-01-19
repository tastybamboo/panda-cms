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

require File.expand_path("../dummy/config/environment", __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

# Add additional requires below this line. Rails is not loaded until this point!
require "shoulda/matchers"
require "capybara"
require "capybara/rspec"
require "view_component/test_helpers"
require "faker"
require "puma"
require "factory_bot_rails"

# Load support files first
Dir[Rails.root.join("../support/**/*.rb")].sort.each { |f| require f }

# Configure FactoryBot
FactoryBot.definition_file_paths = [
  File.join(File.dirname(__FILE__), "factories")
]
FactoryBot.reload

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

module DebugHelpers
  def puts_debug(message)
    puts "[DEBUG] #{message}" if ENV["DEBUG"]
  end
end

RSpec.configure do |config|
  # URL helpers in tests would be nice to use
  config.include Rails.application.routes.url_helpers
  config.include Panda::CMS::Engine.routes.url_helpers

  # Add debug helper method globally
  config.include DebugHelpers

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

  # Log examples to allow using --only-failures and --next-failure
  config.example_status_persistence_file_path = "spec/examples.txt"

  # https://rspec.info/features/3-12/rspec-core/configuration/zero-monkey-patching-mode/
  config.disable_monkey_patching!

  # Use verbose output if only running one spec file
  config.default_formatter = "doc" if config.files_to_run.one?

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  # config.profile_examples = 10

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

  config.include ViewComponent::TestHelpers, type: :view_component
  config.include Capybara::RSpecMatchers, type: :view_component
  config.include FactoryBot::Syntax::Methods

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
end
