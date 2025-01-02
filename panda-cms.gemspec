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
  spec.add_dependency "pg"
  spec.add_dependency "sanitize"
  spec.add_dependency "groupdate"

  spec.add_development_dependency "cuprite"
  spec.add_development_dependency "lookbook"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-json"
  spec.add_development_dependency "tty-box"
  spec.add_development_dependency "tty-screen"

  # temp:
  spec.add_dependency "omniauth", "~> 2.1"

  spec.add_development_dependency "brakeman"
  spec.add_development_dependency "bundle-audit"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "omniauth"
  spec.add_development_dependency "omniauth-github", "~> 2.0"
  spec.add_development_dependency "omniauth-google-oauth2", "~> 1.1"
  spec.add_development_dependency "omniauth-microsoft_graph", "~> 2.0"
  spec.add_development_dependency "omniauth-rails_csrf_protection", "~> 1.0"
  spec.add_development_dependency "shoulda-matchers"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "puma"

  spec.post_install_message = "🐼 💜"
end
