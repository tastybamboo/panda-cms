require_relative "lib/panda-cms/version"

Gem::Specification.new do |spec|
  spec.name = "panda-cms"
  spec.version = Panda::CMS::VERSION
  spec.author = ["Panda Software Limited"]
  spec.email = ["bamboo@pandacms.io"]
  spec.homepage = "https://pandacms.io"
  spec.summary = "Better websites on Rails."
  spec.license = "BSD-3-Clause"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tastybamboo/panda-cms"
  spec.metadata["bug_tracker_uri"] = "https://github.com/tastybamboo/panda-cms/issues"
  spec.metadata["changelog_uri"] = "https://github.com/tastybamboo/panda-cms/releases"
  spec.metadata["github_repo"] = "ssh://github.com/tastybamboo/panda-cms.git"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,public}/**/*", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.0"

  spec.add_dependency "panda-core"
  spec.add_dependency "invisible_captcha"
  spec.add_dependency "pg"
  spec.add_dependency "sanitize"
  spec.add_dependency "groupdate"

  # Development and testing dependencies
  spec.add_development_dependency "annotaterb"
  spec.add_development_dependency "better_errors"
  spec.add_development_dependency "binding_of_caller"
  spec.add_development_dependency "brakeman"
  spec.add_development_dependency "bullet"
  spec.add_development_dependency "bundler-audit"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "cuprite"
  spec.add_development_dependency "danger"
  spec.add_development_dependency "danger-reek"
  spec.add_development_dependency "danger-rubocop"
  spec.add_development_dependency "danger-simplecov_json"
  spec.add_development_dependency "danger-todoist"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "erb_lint"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "fasterer"
  spec.add_development_dependency "generator_spec"
  spec.add_development_dependency "listen"
  spec.add_development_dependency "lookbook", "~> 2"
  spec.add_development_dependency "puma"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-core", "~> 3.13"
  spec.add_development_dependency "rspec-github"
  spec.add_development_dependency "rspec-rails", "~> 7.1"
  spec.add_development_dependency "ruby-lsp"
  spec.add_development_dependency "shoulda-matchers"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-json"
  spec.add_development_dependency "simplecov-lcov"
  spec.add_development_dependency "simplecov_json_formatter"
  spec.add_development_dependency "simplecov_lcov_formatter"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "standard-rails"
  spec.add_development_dependency "stringio", ">= 3.1.2"
  spec.add_development_dependency "tty-box"
  spec.add_development_dependency "tty-screen"
  spec.add_development_dependency "yamllint"
  spec.add_development_dependency "yard-activerecord"

  spec.post_install_message = "🐼 💜"
end
