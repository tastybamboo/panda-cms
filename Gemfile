# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Use panda-core from GitHub
gem "panda-core", github: "tastybamboo/panda-core", branch: "feature/auth-migration-from-cms"

# Use panda-editor gem
gem "panda-editor", "~> 0.1.0"

# Specify your gem's dependencies in panda-cms.gemspec.
gemspec

# Development-only dependencies  
group :development do
  gem "better_errors"
  gem "binding_of_caller"
end

# Development and testing dependencies
group :development, :test do
  gem "annotaterb"
  gem "brakeman"
  gem "bullet"
  gem "bundler-audit"
  gem "capybara"
  gem "cuprite"
  gem "danger"
  gem "danger-reek"
  gem "danger-rubocop"
  gem "danger-simplecov_json"
  gem "danger-todoist"
  gem "database_cleaner-active_record"
  gem "debug"
  gem "erb_lint"
  gem "fasterer"
  gem "generator_spec"
  gem "importmap-rails", ">= 2"
  gem "listen"
  gem "omniauth-github"
  gem "omniauth-google-oauth2"
  gem "omniauth-microsoft_graph"
  gem "propshaft"
  gem "puma"
  gem "rake"
  gem "rspec"
  gem "rspec-core"
  gem "rspec-github"
  gem "rspec-rails"
  gem "ruby-lsp"
  gem "shoulda-matchers"
  gem "simplecov", "~> 0.22"
  gem "simplecov-json"
  gem "simplecov_json_formatter"
  gem "simplecov-lcov"
  gem "simplecov_lcov_formatter"
  gem "standard"
  gem "standard-rails"
  gem "stringio", ">= 3.1.2"
  gem "tty-box"
  gem "tty-screen"
  gem "yamllint"
  gem "yard-activerecord"
end

group :test do
end

gem "rbnacl", "~> 7.1"
gem "tzinfo-data", "~> 1.2025"
gem "msgpack", "~> 1.8"