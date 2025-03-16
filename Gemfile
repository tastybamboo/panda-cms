source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in panda-cms.gemspec.
gemspec

gem "panda-core", github: "tastybamboo/panda-core"
# gem "panda-core", path: "../panda-core"

# Development and testing dependencies
group :development, :test do
  gem "annotaterb"
  gem "better_errors"
  gem "binding_of_caller"
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
  gem "debug"
  gem "erb_lint"
  gem "factory_bot_rails"
  gem "faker"
  gem "fasterer"
  gem "generator_spec"
  gem "listen"
  gem "puma"
  gem "rake"
  gem "rspec"
  gem "rspec-core", "~> 3.13"
  gem "rspec-rails", "~> 7.1"
  gem "ruby-lsp"
  gem "shoulda-matchers"
  gem "simplecov", "~> 0.22"
  gem "simplecov-json"
  gem "simplecov-lcov"
  gem "simplecov_json_formatter"
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
  gem "rspec-github", require: false
  gem "omniauth-google-oauth2"
  gem "omniauth-microsoft_graph"
  gem "omniauth-github"
end
