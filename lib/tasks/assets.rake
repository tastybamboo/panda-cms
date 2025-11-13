# frozen_string_literal: true

# Unified Panda CMS dummy asset tasks
# Mirrors Panda Core behaviour, but tailored for CMS:
#
# Responsibilities:
#   • Compile Propshaft assets for Rails 8 test environment
#   • Copy CMS JS modules into dummy app
#   • Generate importmap.json for the dummy app
#   • Perform deep HTTP-level verification of assets
#   • Fail-fast in CI if anything is missing or broken

namespace :panda do
  namespace :cms do
    namespace :assets do
      #
      # Helper – resolve dummy directory even when tasks are run from engine root
      #
      def dummy_dir
        root = Rails.root
        return root if root.basename.to_s == "dummy"

        candidate = root.join("spec/dummy")
        return candidate if candidate.exist?

        raise("❌ Cannot find dummy root — expected #{candidate}")
      end

      #
      # Helper – HTTP request to the local mini-server
      #
      def http_fetch(path, port)
        require "net/http"
        uri = URI("http://127.0.0.1:#{port}#{path}")
        res = Net::HTTP.get_response(uri)

        return [:ok, res.body] if res.is_a?(Net::HTTPSuccess)
        [:error, res.code]
      rescue => e
        [:exception, e.message]
      end

      #
      # 📦 Compile Propshaft assets (CSS/JS entrypoints for dummy app)
      #
      desc "Compile Panda CMS + dummy Propshaft assets for Rails test environment"
      task :compile_dummy do
        puts "🐼 [Panda CMS] Compiling test assets into dummy app..."
        puts "📁 dummy: #{dummy_dir}"

        Dir.chdir(dummy_dir) do
          # Clean stale assets
          system("bundle exec rails assets:clobber RAILS_ENV=test")

          # Compile Propshaft assets
          success = system("bundle exec rails assets:precompile RAILS_ENV=test")
          raise("❌ Failed to compile Propshaft assets") unless success

          puts "  ✅ Propshaft assets built"

          #
          # Copy CMS JavaScript modules (importmap-based)
          #
          puts "📦 Copying Panda CMS JavaScript modules..."

          engine_js = Panda::CMS::Engine.root.join("app/javascript/panda/cms")
          dest_js = dummy_dir.join("app/javascript/panda/cms")

          FileUtils.mkdir_p(dest_js)
          FileUtils.cp_r(engine_js.children, dest_js)

          puts "  ✅ CMS JS modules copied"
        end
      end

      #
      # 🗺️ Generate importmap.json for dummy environment
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

          puts "  ✓ Wrote importmap.json → #{path}"
        end
      end

      #
      # 🔍 Deep verification: Propshaft manifest + Importmap + HTTP checks
      #
      desc "Verify dummy CMS assets exist and resolve via HTTP (fail-fast for CI)"
      task :verify_dummy do
        require "json"
        require "webrick"

        puts "🔍 [Panda CMS] Verifying dummy asset readiness..."

        assets_dir = dummy_dir.join("public/assets")
        manifest_path = assets_dir.join(".manifest.json")
        importmap_path = assets_dir.join("importmap.json")

        abort("❌ public/assets missing") unless Dir.exist?(assets_dir)
        abort("❌ .manifest.json missing") unless File.exist?(manifest_path)
        abort("❌ importmap.json missing") unless File.exist?(importmap_path)

        manifest = begin
          JSON.parse(File.read(manifest_path))
        rescue
          abort("❌ Invalid manifest JSON")
        end
        importmap = begin
          JSON.parse(File.read(importmap_path))
        rescue
          abort("❌ Invalid importmap JSON")
        end

        puts "  ✓ Manifest loaded (#{manifest.size} entries)"
        puts "  ✓ Importmap loaded (#{importmap["imports"].size} imports)"

        #
        # Start a tiny WEBrick server to serve dummy/public
        #
        server_port = 4579
        server_thread = Thread.new do
          root = dummy_dir.join("public").to_s
          WEBrick::HTTPServer.new(
            Port: server_port,
            DocumentRoot: root,
            AccessLog: [],
            Logger: WEBrick::Log.new(File::NULL)
          ).start
        end

        sleep 0.4

        #
        # Validate importmap assets via HTTP
        #
        puts "🔍 Validating importmap assets via HTTP..."

        importmap["imports"].each do |logical, path|
          res, data = http_fetch("/assets/#{path}", server_port)

          case res
          when :ok
            abort("❌ Empty asset for #{logical}") if data.strip.empty?
            puts "   ✓ #{logical} → /assets/#{path}"
          when :error
            abort("❌ Missing importmap asset #{logical} (HTTP #{data})")
          when :exception
            abort("❌ Fetch error for #{logical}: #{data}")
          end
        end

        #
        # Validate CMS JS modules
        #
        puts "🔍 Validating CMS JS controllers..."

        cms_js_root = dummy_dir.join("app/javascript/panda/cms")
        controllers = Dir.glob(cms_js_root.join("*.js")).map { |f| File.basename(f) }

        controllers.each do |f|
          res, data = http_fetch("/assets/panda/cms/#{f}", server_port)
          abort("❌ CMS JS missing /assets/panda/cms/#{f}") unless res == :ok
          abort("❌ CMS JS empty: #{f}") if data.strip.empty?

          puts "   ✓ #{f}"
        end

        #
        # Validate fingerprinted CSS/JS via Propshaft manifest
        #
        puts "🔍 Validating Propshaft manifest assets via HTTP..."

        manifest.keys.each do |digest_file|
          next unless digest_file.include?("-") # only fingerprinted entries

          res, data = http_fetch("/assets/#{digest_file}", server_port)

          abort("❌ Missing fingerprinted asset #{digest_file}") unless res == :ok
          abort("❌ Fingerprinted asset empty: #{digest_file}") if data.strip.empty?

          puts "   ✓ #{digest_file}"
        end

        Thread.kill(server_thread)

        puts "✅ Panda CMS dummy assets verified (HTTP-level)"
      end
    end
  end
end
