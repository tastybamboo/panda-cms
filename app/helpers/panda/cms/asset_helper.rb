# frozen_string_literal: true

module Panda
  module CMS
    module AssetHelper
      # Include Panda CMS JavaScript and CSS assets
      # Automatically chooses between GitHub-hosted assets (production)
      # and local development assets
      def panda_cms_assets
        Panda::CMS::AssetLoader.asset_tags.html_safe
      end

      # Include only Panda CMS JavaScript
      def panda_cms_javascript
        js_url = Panda::CMS::AssetLoader.javascript_url
        return "" unless js_url

        if Panda::CMS::AssetLoader.use_github_assets?
          # GitHub-hosted assets with integrity check
          version = Panda::CMS::AssetLoader.send(:asset_version)
          integrity = asset_integrity(version, "panda-cms-#{version}.js")

          tag_options = {
            src: js_url,
            type: "module",
            defer: true
          }
          tag_options[:integrity] = integrity if integrity
          tag_options[:crossorigin] = "anonymous" if integrity

          content_tag(:script, "", tag_options)
        else
          # Development assets - check if it's a standalone bundle or importmap
          if js_url.include?("panda-cms-assets")
            # Standalone bundle - don't use type: "module"
            javascript_include_tag(js_url, defer: true)
          else
            # Importmap asset - use type: "module"
            javascript_include_tag(js_url, type: "module", defer: true)
          end
        end
      end

      # Include only Panda CMS CSS
      def panda_cms_stylesheet
        css_url = Panda::CMS::AssetLoader.css_url
        return "" unless css_url

        if Panda::CMS::AssetLoader.use_github_assets?
          # GitHub-hosted assets with integrity check
          version = Panda::CMS::VERSION
          integrity = asset_integrity(version, "panda-cms-#{version}.css")

          tag_options = {
            rel: "stylesheet",
            href: css_url
          }
          tag_options[:integrity] = integrity if integrity
          tag_options[:crossorigin] = "anonymous" if integrity

          tag(:link, tag_options)
        else
          # Development assets
          stylesheet_link_tag(css_url)
        end
      end

      # Get the current Panda CMS version
      def panda_cms_version
        Panda::CMS::VERSION
      end

      # Check if using GitHub-hosted assets
      def using_github_assets?
        Panda::CMS::AssetLoader.use_github_assets?
      end

      # Download and cache assets if needed
      # Call this in an initializer or controller to pre-cache assets
      def ensure_panda_cms_assets!
        Panda::CMS::AssetLoader.ensure_assets_available!
      end

      # Debug information about asset loading
      def panda_cms_asset_debug
        return "" unless Rails.env.development? || Rails.env.test?

        version = Panda::CMS::VERSION
        js_url = Panda::CMS::AssetLoader.javascript_url
        css_url = Panda::CMS::AssetLoader.css_url
        using_github = Panda::CMS::AssetLoader.use_github_assets?
        compiled_available = Panda::CMS::AssetLoader.send(:compiled_assets_available?)

        debug_info = [
          "<!-- Panda CMS Asset Debug Info -->",
          "<!-- Version: #{version} -->",
          "<!-- Using GitHub assets: #{using_github} -->",
          "<!-- Compiled assets available: #{compiled_available} -->",
          "<!-- JavaScript URL: #{js_url} -->",
          "<!-- CSS URL: #{css_url || "none"} -->",
          "<!-- Rails environment: #{Rails.env} -->",
          "<!-- Compiled at: #{Time.now.utc.iso8601} -->"
        ]

        debug_info.join("\n").html_safe
      end

      # Initialize Panda CMS Stimulus application
      # Call this after the asset tags to ensure proper initialization
      def panda_cms_stimulus_init
        javascript_tag(<<~JS, type: "module")
          // Initialize Panda CMS Stimulus application
          document.addEventListener('DOMContentLoaded', function() {
            if (window.pandaCmsStimulus) {
              console.debug('[Panda CMS] Stimulus application initialized');

              // Set debug mode based on Rails environment
              const railsEnv = document.body?.dataset?.environment || 'production';
              window.pandaCmsStimulus.debug = (railsEnv === 'development');

              // Trigger a custom event to signal Panda CMS is ready
              document.dispatchEvent(new CustomEvent('panda-cms:ready', {
                detail: {
                  version: '#{Panda::CMS::VERSION}',
                  usingGitHubAssets: #{Panda::CMS::AssetLoader.use_github_assets?}
                }
              }));
            } else {
              console.warn('[Panda CMS] Stimulus application not found. Assets may not have loaded properly.');
            }
          });
        JS
      end

      # Complete asset loading with initialization
      # This is the recommended way to include all Panda CMS assets
      def panda_cms_complete_assets
        [
          panda_cms_asset_debug,
          panda_cms_assets,
          panda_cms_stimulus_init
        ].join("\n").html_safe
      end

      private

      def asset_integrity(version, filename)
        Panda::CMS::AssetLoader.send(:asset_integrity, version, filename)
      rescue
        nil
      end
    end
  end
end
