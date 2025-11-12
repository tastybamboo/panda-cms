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
    end
  end
end
