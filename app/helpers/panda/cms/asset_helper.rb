# frozen_string_literal: true

require "panda/core"

module Panda
  module CMS
    module AssetHelper
      include Panda::Core::AssetHelper if defined?(Panda::Core::AssetHelper)
      # Include Panda CMS JavaScript and CSS assets
      # Automatically chooses between GitHub-hosted assets (production)
      # and local development assets
      def panda_cms_assets
        tags = []

        # Include Core assets first (if Core is available)
        if defined?(Panda::Core::AssetHelper)
          tags << panda_core_assets
        end

        # Then include CMS-specific assets
        tags << Panda::CMS::AssetLoader.asset_tags

        tags.join("\n").html_safe
      end

      # Include only Panda CMS JavaScript
      def panda_cms_javascript
        # Panda CMS uses importmaps for JavaScript (no compiled bundles)
        # Load CMS controllers after Core is loaded
        # Files are served by Rack::Static middleware from engine's app/javascript
        importmap_html = <<~HTML
          <script type="module" src="/panda/cms/application_panda_cms.js"></script>
          <script type="module" src="/panda/cms/controllers/index.js"></script>
        HTML
        importmap_html.html_safe
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

        debug_info = [
          "<!-- Panda CMS Asset Debug Info -->",
          "<!-- Version: #{version} -->",
          "<!-- Using importmaps: true (no compilation) -->",
          "<!-- JavaScript URL: #{js_url} -->",
          "<!-- CSS URL: #{css_url || "CSS from panda-core"} -->",
          "<!-- Rails environment: #{Rails.env} -->",
          "<!-- Rails root: #{Rails.root} -->"
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
          panda_cms_stimulus_init,
          # Add immediate JavaScript execution test for CI debugging
          (Rails.env.test? ? javascript_tag("window.pandaCmsInlineTest = true; console.log('[Panda CMS] Inline script executed');") : "")
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
