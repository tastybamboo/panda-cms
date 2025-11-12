# frozen_string_literal: true

# Panda CMS follows the same asset strategy as Panda Core:
# - CSS: Provided by Panda Core via Tailwind compilation
# - JavaScript: Served via importmaps using Rack::Static middleware
#
# No asset compilation is needed for Panda CMS.
# All JavaScript controllers are loaded as ES modules via importmap.rb

namespace :panda do
  namespace :cms do
    namespace :assets do
      desc "Verify Panda CMS assets are available"
      task :verify do
        puts "🐼 Verifying Panda CMS asset configuration..."
        puts ""
        puts "📁 JavaScript Controllers:"

        engine_root = Panda::CMS::Engine.root
        controller_files = Dir.glob(engine_root.join("app/javascript/panda/cms/controllers/*.js"))

        controller_files.each do |file|
          next if File.basename(file) == "index.js"
          puts "  ✓ #{File.basename(file)}"
        end

        puts ""
        puts "✅ All assets available via importmaps"
        puts "📖 CSS provided by Panda Core at /panda-core-assets/panda-core.css"
        puts "📖 JavaScript served via importmaps from /panda/cms/..."
        puts ""
        puts "ℹ️  No compilation needed - assets served directly from engine!"
      end

      desc "Prepare test environment assets for dummy app"
      task :compile_dummy do
        puts "🐼 Preparing Panda CMS test assets..."

        # Determine the engine root directory (lib/tasks -> lib -> engine_root)
        engine_root = File.expand_path("../..", __dir__)

        # NOTE: CMS JavaScript is served via importmaps directly from the engine
        # We do NOT need to copy/compile CMS assets - only Propshaft assets for the dummy app

        # 1. Compile Propshaft assets for dummy app
        puts "🔨 Compiling Propshaft assets for test environment..."
        dummy_dir = File.join(engine_root, "spec/dummy")
        Dir.chdir(dummy_dir) do
          system("bundle exec rails assets:precompile RAILS_ENV=test") || raise("Failed to compile Propshaft assets")
        end
        puts "  ✅ Propshaft assets compiled"

        # 2. Generate importmap.json
        puts "🗺️  Generating importmap.json..."
        # Ensure the public/assets directory exists
        assets_dir = File.join(dummy_dir, "public/assets")
        FileUtils.mkdir_p(assets_dir)

        # Load the Rails environment to access importmap
        require File.join(dummy_dir, "config/environment")
        importmap_json = Rails.application.importmap.to_json(resolver: ActionController::Base.helpers)
        importmap_path = File.join(assets_dir, "importmap.json")
        File.write(importmap_path, importmap_json)
        puts "  ✅ Generated #{importmap_path}"

        puts ""
        puts "✅ Test environment assets ready! (CMS JavaScript served via importmaps)"
      end
    end
  end
end
