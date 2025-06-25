# frozen_string_literal: true

require "tailwindcss-rails"
require "tailwindcss/ruby"
require "shellwords"

require "panda/cms/engine"

ENV["TAILWIND_PATH"] ||= Tailwindcss::Engine.root.join("exe/tailwindcss").to_s

namespace :panda do
  namespace :cms do
    desc "Watch admin assets for Panda CMS"
    # We only care about this in development
    task :watch_admin do
      run_tailwind(
        root_path: Panda::CMS::Engine.root,
        input_path: "app/assets/stylesheets/panda/cms/application.tailwind.css",
        output_path: "app/assets/builds/panda.cms.css",
        watch: true,
        minify: false
      )
    end

    desc "Generate missing blocks from template files"
    task generate_missing_blocks: [:environment] do
      Panda::CMS::Template.generate_missing_blocks
    end

    namespace :export do
      desc "Generate a .json export and output to stdout"
      task json: [:environment] do
        puts Panda::CMS::BulkEditor.export
      end
    end
  end
end

task default: %i[spec panda cms]

def run_tailwind(root_path:, input_path: nil, output_path: nil, config_path: nil, watch: false, minify: true)
  config_path ||= root_path.join("config/tailwind.config.js")

  command = [
    Tailwindcss::Ruby.executable,
    "-i #{root_path.join(input_path)}",
    "-o #{root_path.join(output_path)}",
    "-c #{root_path.join(config_path)}"
  ]

  command << "-w" if watch
  command << "-m" if minify

  command = command.join(" ")
  system command
end
