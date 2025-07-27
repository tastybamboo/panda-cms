# frozen_string_literal: true

module Panda
  module CMS
    # AssetLoader handles loading compiled assets from GitHub releases
    # Falls back to local development assets when GitHub assets unavailable
    class AssetLoader
      class << self
        # Generate HTML tags for loading Panda CMS assets
        def asset_tags(options = {})
          if use_github_assets?
            github_asset_tags(options)
          else
            development_asset_tags(options)
          end
        end

        # Get the JavaScript asset URL
        def javascript_url
          if use_github_assets?
            github_javascript_url
          else
            development_javascript_url
          end
        end

        # Get the CSS asset URL (if exists)
        def css_url
          if use_github_assets?
            github_css_url
          else
            development_css_url
          end
        end

        # Check if GitHub-hosted assets should be used
        def use_github_assets?
          # Use GitHub assets in production or when explicitly enabled
          Rails.env.production? ||
            ENV["PANDA_CMS_USE_GITHUB_ASSETS"] == "true" ||
            !development_assets_available? ||
            ((Rails.env.test? || in_test_environment?) && compiled_assets_available?)
        end

        # Download assets from GitHub to local cache
        def ensure_assets_available!
          return if development_assets_available? && !use_github_assets?

          cache_dir = local_cache_directory
          version = `git rev-parse --short HEAD`.strip

          # Check if we already have cached assets for this version
          if cached_assets_exist?(version)
            Rails.logger.info "[Panda CMS] Using cached assets #{version}"
            return
          end

          Rails.logger.info "[Panda CMS] Downloading assets #{version} from GitHub..."
          download_github_assets(version, cache_dir)
        end

        private

        def github_asset_tags(options = {})
          version = asset_version
          base_url = github_base_url(version)

          tags = []

          # JavaScript tag with integrity check
          js_url = "#{base_url}panda-cms-#{version}.js"
          integrity = asset_integrity(version, "panda-cms-#{version}.js")

          js_attrs = {
            src: js_url
          }
          # In CI environment, don't use defer to ensure immediate execution
          js_attrs[:defer] = true unless ENV["GITHUB_ACTIONS"] == "true"
          # Standalone bundles should NOT use type="module" - they're regular scripts
          # Only use type="module" for importmap/ES module assets
          if !js_url.include?("panda-cms-assets")
            js_attrs[:type] = "module"
          end
          js_attrs[:integrity] = integrity if integrity
          js_attrs[:crossorigin] = "anonymous" if integrity

          tags << content_tag(:script, "", js_attrs)

          # CSS tag if CSS bundle exists
          css_url = "#{base_url}panda-cms-#{version}.css"
          if github_asset_exists?(version, "panda-cms-#{version}.css")
            css_integrity = asset_integrity(version, "panda-cms-#{version}.css")

            css_attrs = {
              rel: "stylesheet",
              href: css_url
            }
            css_attrs[:integrity] = css_integrity if css_integrity
            css_attrs[:crossorigin] = "anonymous" if css_integrity

            tags << tag(:link, css_attrs)
          end

          tags.join("\n").html_safe
        end

        def development_asset_tags(options = {})
          # In development, use importmap or local assets
          if defined?(Rails.application.importmap)
            # Use importmap for development
            javascript_importmap_tags
          else
            # Fallback to basic script tag
            content_tag(:script, "", {
              src: development_javascript_url,
              type: "module",
              defer: true
            })
          end
        end

        def github_javascript_url
          version = asset_version
          # In test environment with local compiled assets, use local URL
          if Rails.env.test? && compiled_assets_available?
            "/panda-cms-assets/panda-cms-#{version}.js"
          else
            "#{github_base_url(version)}panda-cms-#{version}.js"
          end
        end

        def github_css_url
          version = asset_version
          # In test environment with local compiled assets, use local URL
          if Rails.env.test? && compiled_assets_available?
            "/panda-cms-assets/panda-cms-#{version}.css"
          else
            "#{github_base_url(version)}panda-cms-#{version}.css"
          end
        end

        def development_javascript_url
          # Try cached assets first, then importmap
          version = asset_version
          # Try root level first (standalone bundle), then versioned directory
          root_path = "/panda-cms-assets/panda-cms-#{version}.js"
          versioned_path = "/panda-cms-assets/#{version}/panda-cms-#{version}.js"

          if cached_asset_exists?(root_path)
            root_path
          elsif cached_asset_exists?(versioned_path)
            versioned_path
          else
            # Fallback to importmap or engine asset
            "/assets/panda/cms/controllers/index.js"
          end
        end

        def development_css_url
          version = asset_version
          # Try versioned directory first, then root level
          versioned_path = "/panda-cms-assets/#{version}/panda-cms-#{version}.css"
          root_path = "/panda-cms-assets/panda-cms-#{version}.css"

          if cached_asset_exists?(versioned_path)
            versioned_path
          elsif cached_asset_exists?(root_path)
            root_path
          else
            nil # No CSS in development mode typically
          end
        end

        def github_base_url(version)
          # In test environment with compiled assets, use local URLs
          if (Rails.env.test? || in_test_environment?) && compiled_assets_available?
            "/panda-cms-assets/"
          else
            "https://github.com/tastybamboo/panda-cms/releases/download/#{version}/"
          end
        end

        def asset_version
          # In test environment, use VERSION constant for consistency with compiled assets
          # In other environments, use git SHA for dynamic versioning
          # Also check for test environment indicators since Rails.env might be development in specs
          if Rails.env.test? || ENV["CI"].present? || in_test_environment?
            Panda::CMS::VERSION
          else
            `git rev-parse --short HEAD`.strip
          end
        end

        def in_test_environment?
          # Check if we're running specs even if Rails.env is development
          defined?(RSpec) && RSpec.respond_to?(:configuration)
        end

        def compiled_assets_available?
          # Check if compiled assets exist in test location
          version = asset_version
          js_file = Rails.public_path.join("panda-cms-assets", "panda-cms-#{version}.js")
          css_file = Rails.public_path.join("panda-cms-assets", "panda-cms-#{version}.css")
          js_file.exist? && css_file.exist?
        end

        def development_assets_available?
          # Check if local development assets exist (importmap, etc.)
          importmap_available? || engine_assets_available?
        end

        def importmap_available?
          return false unless defined?(Rails.application.importmap)

          begin
            # Rails 8+ uses a different API for accessing importmap entries
            if Rails.application.importmap.respond_to?(:to_json)
              importmap_json = JSON.parse(Rails.application.importmap.to_json)
              importmap_json.any? { |name, _| name.include?("panda") }
            elsif Rails.application.importmap.respond_to?(:entries)
              Rails.application.importmap.entries.any? { |entry| entry.name.include?("panda") }
            else
              false
            end
          rescue => e
            Rails.logger.debug "[Panda CMS] Could not check importmap: #{e.message}"
            false
          end
        end

        def engine_assets_available?
          # Check if engine's JavaScript files are available
          engine_js_path = Rails.root.join("..", "..", "app", "javascript", "panda", "cms", "controllers", "index.js")
          File.exist?(engine_js_path)
        end

        def cached_assets_exist?(version)
          cache_dir = local_cache_directory.join(version)
          cache_dir.exist? && cache_dir.join("panda-cms-#{version}.js").exist?
        end

        def cached_asset_exists?(path)
          Rails.public_path.join(path.delete_prefix("/")).exist?
        end

        def local_cache_directory
          Rails.public_path.join("panda-cms-assets")
        end

        def download_github_assets(version, cache_dir)
          require "net/http"
          require "uri"
          require "json"

          version_dir = cache_dir.join(version)
          FileUtils.mkdir_p(version_dir)

          # Download manifest first
          manifest_url = "#{github_base_url(version)}manifest.json"

          begin
            manifest_response = fetch_url(manifest_url)
            if manifest_response.success?
              manifest = JSON.parse(manifest_response.body)

              # Download each file
              manifest["files"].each do |file_info|
                filename = file_info["filename"]
                file_url = "#{github_base_url(version)}#{filename}"

                Rails.logger.debug "[Panda CMS] Downloading #{filename}..."

                file_response = fetch_url(file_url)
                if file_response.success?
                  File.write(version_dir.join(filename), file_response.body)
                  Rails.logger.debug "[Panda CMS] Downloaded #{filename}"
                else
                  Rails.logger.warn "[Panda CMS] Failed to download #{filename}: #{file_response.code}"
                end
              end

              # Save manifest
              File.write(version_dir.join("manifest.json"), manifest_response.body)
              Rails.logger.info "[Panda CMS] Assets cached locally"
            else
              Rails.logger.warn "[Panda CMS] Failed to download manifest: #{manifest_response.code}"
            end
          rescue => e
            Rails.logger.error "[Panda CMS] Error downloading assets: #{e.message}"
            # Fall back to development mode
          end
        end

        def fetch_url(url)
          uri = URI(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")
          http.open_timeout = 10
          http.read_timeout = 30

          request = Net::HTTP::Get.new(uri)
          request["User-Agent"] = "Panda-CMS/#{`git rev-parse --short HEAD`}"

          response = http.request(request)

          OpenStruct.new(
            success?: response.code.to_i == 200,
            code: response.code,
            body: response.body
          )
        rescue => e
          Rails.logger.error "[Panda CMS] Network error: #{e.message}"
          OpenStruct.new(success?: false, code: "error", body: nil)
        end

        def asset_integrity(version, filename)
          # Try to get integrity from cached manifest
          manifest_path = local_cache_directory.join(version, "manifest.json")
          return nil unless manifest_path.exist?

          begin
            manifest = JSON.parse(File.read(manifest_path))
            file_info = manifest["files"].find { |f| f["filename"] == filename }
            return nil unless file_info

            "sha256-#{Base64.strict_encode64([file_info["sha256"]].pack("H*"))}"
          rescue => e
            Rails.logger.warn "[Panda CMS] Error reading asset integrity: #{e.message}"
            nil
          end
        end

        def github_asset_exists?(version, filename)
          # Quick check - assume it exists for now
          # Could be enhanced to do HEAD request
          true
        end

        def content_tag(name, content, options = {})
          if defined?(ActionView::Helpers::TagHelper)
            # Create a view context to render the tag
            view_context = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
            view_context.content_tag(name, content, options)
          else
            # Fallback implementation
            attrs = options.map { |k, v| %(#{k}="#{v}") }.join(" ")
            if content.present?
              "<#{name} #{attrs}>#{content}</#{name}>"
            else
              "<#{name} #{attrs}></#{name}>"
            end
          end
        end

        def tag(name, options = {})
          if defined?(ActionView::Helpers::TagHelper)
            # Create a view context to render the tag
            view_context = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
            view_context.tag(name, options)
          else
            # Fallback implementation
            attrs = options.map { |k, v| %(#{k}="#{v}") }.join(" ")
            "<#{name} #{attrs}>"
          end
        end
      end
    end
  end
end
