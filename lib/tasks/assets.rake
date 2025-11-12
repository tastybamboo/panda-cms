# frozen_string_literal: true

# Unified Panda CMS dummy asset tasks
# Matches Panda Core behaviour (run inside spec/dummy)
#
# Responsibilities:
#   • Compile Propshaft assets for Rails 8 test environment
#   • Generate importmap.json for the dummy app
#   • Fail-fast for CI if anything is missing
#   • Keep CMS JS importmap-based and uncompiled

namespace :panda do
  namespace :cms do
    namespace :assets do
      #
      # Helper — resolve dummy directory even when tasks are run from engine root
      #
      def dummy_dir
        root = Rails.root

        return root if root.basename.to_s == "dummy"

        candidate = root.join("spec/dummy")
        return candidate if candidate.exist?

        raise("❌ Cannot find dummy root — expected #{candidate}")
      end

      #
      # 📦 Compile Propshaft assets (CSS/JS entrypoints for dummy app)
      #
      desc "Compile Panda CMS + dummy Propshaft assets for Rails test environment"
      task :compile_dummy do
        puts "🐼 [Panda CMS] Compiling test assets into dummy app..."
        puts "📁 dummy: #{dummy_dir}"

        Dir.chdir(dummy_dir) do
          # Clean up stale assets
          system("bundle exec rails assets:clobber RAILS_ENV=test")

          # Compile Propshaft assets
          success = system("bundle exec rails assets:precompile RAILS_ENV=test")

          raise("❌ Failed to compile Propshaft assets") unless success

          puts "  ✅ Propshaft assets built"
        end
      end

      #
      # 🗺️ Generate importmap.json for test/dummy environment
      #
      desc "Generate importmap.json for Rails 8 dummy app"
      task :generate_dummy_importmap do
        puts "🗺️  [Panda CMS] Generating importmap.json..."

        Dir.chdir(dummy_dir) do
          require dummy_dir.join("config/environment")

          json = Rails.application.importmap.to_json(
            resolver: ActionController::Base.helpers
          )

          output_dir = dummy_dir.join("public/assets")
          FileUtils.mkdir_p(output_dir)

          path = output_dir.join("importmap.json")
          File.write(path, json)

          puts "  ✅ Wrote importmap.json → #{path}"
        end
      end

      #
      # 🔍 Verify that CMS + Core assets are present in dummy app
      #
      desc "Verify dummy CMS assets exist (fail-fast for CI)"
      task :verify_dummy do
        puts "🔍 [Panda CMS] Verifying dummy asset readiness..."
        public_assets = dummy_dir.join("public/assets")

        unless File.exist?(public_assets)
          puts "❌ public/assets missing in dummy app"
          exit 1
        end

        # Propshaft manifest
        manifest = public_assets.join(".manifest.json")
        unless File.exist?(manifest)
          puts "❌ .manifest.json missing (Propshaft did not compile)"
          exit 1
        end

        # Importmap.json
        importmap = public_assets.join("importmap.json")
        unless File.exist?(importmap)
          puts "❌ importmap.json missing"
          exit 1
        end

        puts "  📁 public/assets/"
        puts Dir.children(public_assets).map { |f| "   • #{f}" }

        puts "  📄 Manifest OK: #{manifest}"
        puts "  🗺️ Importmap OK: #{importmap}"
        puts "✅ Panda CMS dummy assets verified"
      end
    end
  end
end
