# frozen_string_literal: true

namespace :panda_cms do
  namespace :assets do
    desc "Compile Panda CMS assets for GitHub release distribution"
    task :compile do
      puts "🐼 Compiling Panda CMS assets..."

      # Create output directory
      output_dir = Rails.root.join("tmp", "panda_cms_assets")
      FileUtils.mkdir_p(output_dir)

      version = Panda::CMS::VERSION
      puts "Version: #{version}"

      # Compile JavaScript bundle
      js_bundle = compile_javascript_bundle(version)
      js_file = output_dir.join("panda-cms-#{version}.js")
      File.write(js_file, js_bundle)
      puts "✅ JavaScript compiled: #{js_file} (#{File.size(js_file)} bytes)"

      # Compile CSS bundle (if any CSS files exist)
      css_bundle = compile_css_bundle(version)
      if css_bundle && !css_bundle.strip.empty?
        css_file = output_dir.join("panda-cms-#{version}.css")
        File.write(css_file, css_bundle)
        puts "✅ CSS compiled: #{css_file} (#{File.size(css_file)} bytes)"
      end

      # Create manifest file
      manifest = create_asset_manifest(version)
      manifest_file = output_dir.join("manifest.json")
      File.write(manifest_file, JSON.pretty_generate(manifest))
      puts "✅ Manifest created: #{manifest_file}"

      puts "🎉 Asset compilation complete!"
      puts "📁 Output directory: #{output_dir}"
    end

    desc "Upload compiled assets to GitHub release"
    task :upload => :compile do
      version = Panda::CMS::VERSION
      output_dir = Rails.root.join("tmp", "panda_cms_assets")

      puts "📤 Uploading assets to GitHub release v#{version}..."

      # Check if gh CLI is available
      unless system("gh --version > /dev/null 2>&1")
        puts "❌ GitHub CLI (gh) not found. Please install: https://cli.github.com/"
        exit 1
      end

      # Check if release exists
      unless system("gh release view v#{version} > /dev/null 2>&1")
        puts "❌ Release v#{version} not found. Create it first with: gh release create v#{version}"
        exit 1
      end

      # Upload each asset file
      Dir.glob(output_dir.join("*")).each do |file|
        filename = File.basename(file)
        puts "Uploading #{filename}..."

        if system("gh release upload v#{version} #{file} --clobber")
          puts "✅ Uploaded: #{filename}"
        else
          puts "❌ Failed to upload: #{filename}"
          exit 1
        end
      end

      puts "🎉 All assets uploaded successfully!"
    end

    desc "Download assets from GitHub release for local development"
    task :download do
      version = Panda::CMS::VERSION
      output_dir = Rails.root.join("public", "panda-cms-assets", version)
      FileUtils.mkdir_p(output_dir)

      puts "📥 Downloading assets from GitHub release v#{version}..."

      # Download manifest first to know what files to get
      manifest_url = "https://github.com/pandacms/panda-cms/releases/download/v#{version}/manifest.json"

      begin
        require 'net/http'
        require 'uri'

        uri = URI(manifest_url)
        response = Net::HTTP.get_response(uri)

        if response.code == '200'
          manifest = JSON.parse(response.body)
          puts "✅ Downloaded manifest"

          # Download each file listed in manifest
          manifest['files'].each do |file_info|
            filename = file_info['filename']
            file_url = "https://github.com/pandacms/panda-cms/releases/download/v#{version}/#{filename}"

            puts "Downloading #{filename}..."
            file_uri = URI(file_url)
            file_response = Net::HTTP.get_response(file_uri)

            if file_response.code == '200'
              File.write(output_dir.join(filename), file_response.body)
              puts "✅ Downloaded: #{filename}"
            else
              puts "❌ Failed to download: #{filename}"
            end
          end

          puts "🎉 Assets downloaded to: #{output_dir}"
        else
          puts "❌ Failed to download manifest from: #{manifest_url}"
          puts "Response: #{response.code} #{response.message}"
        end
      rescue => e
        puts "❌ Error downloading assets: #{e.message}"
        puts "Falling back to local development mode..."
      end
    end
  end
end

private

def compile_javascript_bundle(version)
  js_files = [
    Rails.root.join("..", "..", "app", "javascript", "panda", "cms", "controllers", "dashboard_controller.js"),
    Rails.root.join("..", "..", "app", "javascript", "panda", "cms", "controllers", "editor_form_controller.js"),
    Rails.root.join("..", "..", "app", "javascript", "panda", "cms", "controllers", "editor_iframe_controller.js"),
    Rails.root.join("..", "..", "app", "javascript", "panda", "cms", "controllers", "slug_controller.js"),
    Rails.root.join("..", "..", "app", "javascript", "panda", "cms", "controllers", "theme_form_controller.js")
  ]

  bundle = []
  bundle << "// Panda CMS JavaScript Bundle v#{version}"
  bundle << "// Compiled: #{Time.now.utc.iso8601}"
  bundle << ""

  # Add Stimulus application setup
  bundle << "// Stimulus Application Setup"
  bundle << "import { Application } from '@hotwired/stimulus';"
  bundle << "const pandaCmsApplication = Application.start();"
  bundle << "pandaCmsApplication.debug = false; // Set to true for debugging"
  bundle << ""

  # Process each controller file
  js_files.each do |file_path|
    next unless File.exist?(file_path)

    filename = File.basename(file_path, '.js')
    controller_name = filename.sub('_controller', '').tr('_', '-')

    bundle << "// #{filename}"

    # Read and process the controller file
    content = File.read(file_path)

    # Transform ES6 import to inline class definition
    # This is a simple transformation - for complex cases you might need a proper JS parser
    content = content.gsub(/import\s+\{[^}]+\}\s+from\s+["'][^"']+["'];?\s*/, '')
    content = content.gsub(/export\s+default\s+class\s+extends\s+Controller/, "class #{filename.camelize}Controller extends Controller")

    bundle << content
    bundle << ""
    bundle << "// Register controller"
    bundle << "pandaCmsApplication.register('#{controller_name}', #{filename.camelize}Controller);"
    bundle << ""
  end

  # Add TailwindCSS Stimulus Components registration
  bundle << "// TailwindCSS Stimulus Components (placeholder for CDN loading)"
  bundle << "// These will be loaded from CDN in the browser"
  bundle << ""

  bundle << "// Export application for global access"
  bundle << "window.pandaCmsStimulus = pandaCmsApplication;"

  bundle.join("\n")
end

def compile_css_bundle(version)
  css_files = Dir.glob(Rails.root.join("..", "..", "app", "assets", "stylesheets", "**", "*.{css,scss}"))

  return nil if css_files.empty?

  bundle = []
  bundle << "/* Panda CMS CSS Bundle v#{version} */"
  bundle << "/* Compiled: #{Time.now.utc.iso8601} */"
  bundle << ""

  css_files.each do |file_path|
    filename = File.basename(file_path)
    bundle << "/* #{filename} */"
    bundle << File.read(file_path)
    bundle << ""
  end

  bundle.join("\n")
end

def create_asset_manifest(version)
  output_dir = Rails.root.join("tmp", "panda_cms_assets")

  files = Dir.glob(output_dir.join("*")).reject { |f| File.basename(f) == "manifest.json" }.map do |file|
    {
      filename: File.basename(file),
      size: File.size(file),
      sha256: Digest::SHA256.file(file).hexdigest
    }
  end

  {
    version: version,
    compiled_at: Time.now.utc.iso8601,
    files: files,
    cdn_base_url: "https://github.com/tastybamboo/panda-cms/releases/download/v#{version}/",
    integrity: {
      algorithm: "sha256"
    }
  }
end
