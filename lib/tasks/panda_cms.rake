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

    namespace :demo do
      desc "Generate The Panda Sanctuary demo site with comprehensive test data"
      task sanctuary: [:environment] do
        puts "=" * 60
        puts "Generating The Panda Sanctuary demo site..."
        puts "=" * 60
        puts ""

        Panda::CMS::SanctuaryDemo.generate!

        puts ""
        puts "=" * 60
        puts "Demo site generated successfully!"
        puts ""
        puts "To view the demo:"
        puts "  1. cd spec/dummy"
        puts "  2. bin/dev"
        puts "  3. Visit http://localhost:3000"
        puts ""
        puts "Admin panel: http://localhost:3000/admin"
        puts "=" * 60
      end

      desc "Reset and regenerate the demo site (clears existing data)"
      task reset: [:environment] do
        puts "Resetting demo site data..."

        # Clear existing data in reverse dependency order
        Panda::CMS::BlockContent.delete_all
        Panda::CMS::Block.delete_all
        Panda::CMS::MenuItem.delete_all
        Panda::CMS::Menu.delete_all
        Panda::CMS::FormSubmission.delete_all
        Panda::CMS::FormField.delete_all
        Panda::CMS::Form.delete_all
        Panda::CMS::Post.delete_all
        Panda::CMS::Redirect.delete_all
        Panda::CMS::Page.delete_all
        Panda::CMS::Template.delete_all

        puts "Existing data cleared. Generating fresh demo..."

        Rake::Task["panda:cms:demo:sanctuary"].invoke
      end
    end
  end
end

task default: %i[spec panda cms]
