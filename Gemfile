# frozen_string_literal: true

source "https://rubygems.org"

gem "panda-core", github: "tastybamboo/panda-core", branch: "main"
gem "panda-editor", github: "tastybamboo/panda-editor", branch: "main"

# Fix for CI: explicitly specify benchmark version to avoid conflicts with default gem
gem "benchmark", "~> 0.5"

# Specify your gem's dependencies in panda-cms.gemspec
gemspec

# Pin to Rails 8.1.1 to avoid Rails 8.1.2 compatibility issues:
# - FrozenError with autoload_paths and middleware stack
# - phlex-rails 2.3.1 incompatibility
# TODO: Remove pin once panda-core and phlex-rails are updated for Rails 8.1.2
gem "rails", "= 8.1.1"
gem "tzinfo-data"

# Development and testing dependencies
group :development, :test do
  gem "annotaterb"
  gem "awesome_print"
  gem "brakeman"
  gem "bullet"
  gem "bundler-audit"
  gem "capybara"
  gem "cuprite"
  gem "debug"
  gem "erb_lint"
  gem "fasterer"
  gem "importmap-rails"
  gem "listen"
  gem "parallel_tests"
  gem "propshaft"
  gem "puma"
  gem "rake"
  gem "ruby-lsp"
  gem "sqlite3"
  gem "standard"
  gem "standard-rails"
  gem "stringio"
  gem "yard-activerecord"

  # OAuth provider gems (optional - host apps install what they need)
  # Included here for testing purposes
  gem "omniauth-google-oauth2"
  gem "omniauth-github"
  gem "omniauth-microsoft_graph"
end

# Don't include these in test environment, or parsing test failures is hard
group :development do
  gem "better_errors"
  gem "binding_of_caller"
end

# We only need these in the test environment
group :test do
  gem "database_cleaner-active_record"
  gem "rspec"
  gem "rspec-core"
  gem "rspec-github"
  gem "rspec-rails"
  gem "shoulda-matchers"
  gem "simplecov"
  gem "simplecov-json"
  gem "simplecov-lcov"
  gem "simplecov_json_formatter"
  gem "simplecov_lcov_formatter"
end
