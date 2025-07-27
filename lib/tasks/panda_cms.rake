# frozen_string_literal: true

require "tailwindcss-rails"
require "tailwindcss/ruby"
require "shellwords"

require "panda/cms/engine"

ENV["TAILWIND_PATH"] ||= Tailwindcss::Engine.root.join("exe/tailwindcss").to_s

namespace :panda do
  namespace :cms do
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
