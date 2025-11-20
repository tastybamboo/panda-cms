# frozen_string_literal: true

require_relative "lib/panda/cms/version"

Gem::Specification.new do |spec|
  spec.name = "panda-cms"
  spec.version = Panda::CMS::VERSION
  spec.author = ["Otaina Limited", "James Inman"]
  spec.email = ["james@otaina.co.uk"]
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

  spec.add_dependency "awesome_nested_set", ">= 3.8.0"
  spec.add_dependency "down"
  spec.add_dependency "faraday"
  spec.add_dependency "faraday-multipart"
  spec.add_dependency "faraday-retry"
  spec.add_dependency "groupdate"
  spec.add_dependency "http"
  spec.add_dependency "importmap-rails", ">= 2"
  spec.add_dependency "invisible_captcha"
  spec.add_dependency "panda-core"
  spec.add_dependency "panda-editor"
  spec.add_dependency "pg"
  spec.add_dependency "propshaft"
  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "sanitize"
  spec.add_dependency "silencer"
  spec.add_dependency "tailwindcss-rails"

  spec.post_install_message = "🐼 💜"
end
