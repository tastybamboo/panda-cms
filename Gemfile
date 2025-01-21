source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in panda-cms.gemspec.
gemspec

gem "panda-core", path: "../panda-core"

group :test do
  gem "rspec-github", require: false
  gem "omniauth-google-oauth2"
  gem "omniauth-microsoft_graph"
  gem "omniauth-github"
end

# TODO: Load all development gems from panda-dev.Gemfile? :-/
