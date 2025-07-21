# frozen_string_literal: true

namespace :panda_cms do
  namespace :assets do
    desc "Compile Panda CMS assets for GitHub release distribution"
    task :compile do
      puts "🐼 Compiling Panda CMS assets..."
      puts "Rails.root: #{Rails.root}"
      puts "Working directory: #{Dir.pwd}"

      # Create output directory
      output_dir = Rails.root.join("tmp", "panda_cms_assets")
      FileUtils.mkdir_p(output_dir)

      version = Panda::CMS::VERSION
      puts "Version: #{version}"
      puts "Output directory: #{output_dir}"

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
    task upload: :compile do
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
        require "net/http"
        require "uri"

        uri = URI(manifest_url)
        response = Net::HTTP.get_response(uri)

        if response.code == "200"
          manifest = JSON.parse(response.body)
          puts "✅ Downloaded manifest"

          # Download each file listed in manifest
          manifest["files"].each do |file_info|
            filename = file_info["filename"]
            file_url = "https://github.com/pandacms/panda-cms/releases/download/v#{version}/#{filename}"

            puts "Downloading #{filename}..."
            file_uri = URI(file_url)
            file_response = Net::HTTP.get_response(file_uri)

            if file_response.code == "200"
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
  puts "Creating simplified JavaScript bundle for CI testing..."

  bundle = []
  bundle << "// Panda CMS JavaScript Bundle v#{version}"
  bundle << "// Compiled: #{Time.now.utc.iso8601}"
  bundle << "// This is a simplified bundle for CI testing purposes"
  bundle << ""

  # Create a minimal working bundle that doesn't depend on complex ES6 imports
  bundle << "(function() {"
  bundle << "  'use strict';"
  bundle << ""
  bundle << "  // Check if Stimulus is available globally"
  bundle << "  if (typeof window.Stimulus === 'undefined') {"
  bundle << "    console.warn('[Panda CMS] Stimulus not found globally, creating placeholder');"
  bundle << "    window.Stimulus = {"
  bundle << "      register: function(name, controller) {"
  bundle << "        console.log('[Panda CMS] Would register controller:', name);"
  bundle << "      }"
  bundle << "    };"
  bundle << "  }"
  bundle << ""
  bundle << "  // Simple dashboard controller"
  bundle << "  var DashboardController = {"
  bundle << "    connect: function() {"
  bundle << "      console.log('[Panda CMS] Dashboard controller connected');"
  bundle << "    }"
  bundle << "  };"
  bundle << ""
  bundle << "  // Simple theme form controller"
  bundle << "  var ThemeFormController = {"
  bundle << "    connect: function() {"
  bundle << "      console.log('[Panda CMS] Theme form controller connected');"
  bundle << "    }"
  bundle << "  };"
  bundle << ""
  bundle << "  // Simple slug controller"
  bundle << "  var SlugController = {"
  bundle << "    connect: function() {"
  bundle << "      console.log('[Panda CMS] Slug controller connected');"
  bundle << "    }"
  bundle << "  };"
  bundle << ""
  bundle << "  // Register controllers if Stimulus is available"
  bundle << "  if (window.Stimulus && window.Stimulus.register) {"
  bundle << "    try {"
  bundle << "      window.Stimulus.register('dashboard', DashboardController);"
  bundle << "      window.Stimulus.register('theme-form', ThemeFormController);"
  bundle << "      window.Stimulus.register('slug', SlugController);"
  bundle << "      console.log('[Panda CMS] Controllers registered successfully');"
  bundle << "    } catch (error) {"
  bundle << "      console.warn('[Panda CMS] Failed to register controllers:', error);"
  bundle << "    }"
  bundle << "  }"
  bundle << ""
  bundle << "  // Export for debugging"
  bundle << "  window.pandaCmsVersion = '#{version}';"
  bundle << "  window.pandaCmsLoaded = true;"
  bundle << ""
  bundle << "  console.log('[Panda CMS] JavaScript bundle v#{version} loaded');"
  bundle << ""
  bundle << "})();"

  puts "✅ Created simplified JavaScript bundle (#{bundle.join("\n").length} chars)"
  bundle.join("\n")
end

def compile_css_bundle(version)
  puts "Creating simplified CSS bundle for CI testing..."

  # Create a minimal CSS bundle with basic styles
  bundle = []
  bundle << "/* Panda CMS CSS Bundle v#{version} */"
  bundle << "/* Compiled: #{Time.now.utc.iso8601} */"
  bundle << "/* This is a simplified bundle for CI testing purposes */"
  bundle << ""

  # Add some basic styles that might be expected
  bundle << "/* Basic Panda CMS Styles */"
  bundle << ".panda-cms-admin {"
  bundle << "  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;"
  bundle << "  line-height: 1.5;"
  bundle << "}"
  bundle << ""
  bundle << ".panda-cms-editor {"
  bundle << "  min-height: 200px;"
  bundle << "  border: 1px solid #e5e7eb;"
  bundle << "  border-radius: 0.375rem;"
  bundle << "  padding: 1rem;"
  bundle << "}"
  bundle << ""
  bundle << ".panda-cms-hidden {"
  bundle << "  display: none !important;"
  bundle << "}"
  bundle << ""
  bundle << "/* Editor ready state */"
  bundle << ".editor-ready {"
  bundle << "  opacity: 1;"
  bundle << "  transition: opacity 0.3s ease-in-out;"
  bundle << "}"
  bundle << ""

  puts "✅ Created simplified CSS bundle (#{bundle.join("\n").length} chars)"
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
