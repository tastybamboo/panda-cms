# frozen_string_literal: true

module Panda
  module CMS
    module SEOHelper
      #
      # Renders all SEO meta tags for a given page or post
      #
      # @param resource [Panda::CMS::Page, Panda::CMS::Post] The page or post to render meta tags for
      # @return [String] HTML meta tags
      # @visibility public
      #
      def render_seo_meta_tags(resource)
        return "" if resource.blank?

        tags = []

        # Basic SEO tags
        tags << tag.meta(name: "description", content: resource.effective_seo_description) if resource.effective_seo_description.present?
        tags << tag.meta(name: "keywords", content: resource.seo_keywords) if resource.seo_keywords.present?
        tags << tag.meta(name: "robots", content: resource.robots_meta_content)
        tags << tag.link(rel: "canonical", href: canonical_url_for(resource))

        # Open Graph tags
        tags << tag.meta(property: "og:title", content: resource.effective_og_title)
        tags << tag.meta(property: "og:description", content: resource.effective_og_description) if resource.effective_og_description.present?
        tags << tag.meta(property: "og:type", content: resource.og_type)
        tags << tag.meta(property: "og:url", content: canonical_url_for(resource))

        # Image URL for OG and Twitter (compute once)
        og_image_url = variant_representation_url(resource.og_image.variant(:og_share)) if resource.og_image.attached?

        # Open Graph image
        if og_image_url
          tags << tag.meta(property: "og:image", content: og_image_url)
          tags << tag.meta(property: "og:image:width", content: "1200")
          tags << tag.meta(property: "og:image:height", content: "630")
        end

        # Twitter Card tags (with fallback to OG)
        tags << tag.meta(name: "twitter:card", content: "summary_large_image")
        tags << tag.meta(name: "twitter:title", content: resource.effective_og_title)
        tags << tag.meta(name: "twitter:description", content: resource.effective_og_description) if resource.effective_og_description.present?
        tags << tag.meta(name: "twitter:image", content: og_image_url) if og_image_url

        safe_join(tags, "\n")
      end

      #
      # Renders just the page title with SEO optimization
      #
      # @param resource [Panda::CMS::Page, Panda::CMS::Post] The page or post
      # @param separator [String] Separator between page title and site name
      # @param site_name [String] The site name (optional)
      # @return [String] Formatted page title
      # @visibility public
      #
      def seo_title(resource, separator: " · ", site_name: nil)
        parts = [resource.effective_seo_title]
        parts << site_name if site_name.present?
        safe_join(parts, separator)
      end

      private

      # Generates a URL for an ActiveStorage variant, compatible with both Rails 7.x and 8.1+.
      # In Rails 8.1+, url_for(variant) broke because VariantWithRecord dropped to_model,
      # and rails_representation_url was renamed to rails_blob_representation_proxy_url.
      # Avoids eager processing — uses variant.blob and variant.variation directly so the
      # variant is only processed lazily when the representation URL is requested by a client.
      #
      # Note: ActiveStorage route helpers are not mixed into ActionView::Base in Rails 8.1+,
      # so we access them via Rails.application.routes.url_helpers instead of respond_to?.
      def variant_representation_url(variant)
        url_helpers = Rails.application.routes.url_helpers
        if url_helpers.respond_to?(:rails_blob_representation_proxy_url)
          # Rails 8.1+
          url_helpers.rails_blob_representation_proxy_url(
            variant.blob.signed_id,
            variant.variation.key,
            variant.blob.filename,
            host: request.host_with_port,
            protocol: request.protocol
          )
        else
          # Rails 7.x
          url_for(variant)
        end
      rescue NoMethodError, ActionController::UrlGenerationError => e
        Rails.logger.warn "[Panda CMS] Failed to generate variant URL: #{e.message}"
        nil
      end

      #
      # Generates the full canonical URL for a resource
      #
      # @param resource [Panda::CMS::Page, Panda::CMS::Post] The page or post
      # @return [String] Full canonical URL
      # @visibility private
      #
      def canonical_url_for(resource)
        # If canonical_url is a full URL, use it as-is
        return resource.canonical_url if resource.canonical_url&.match?(%r{\Ahttps?://})

        # Otherwise, construct from the path
        path = resource.effective_canonical_url
        "#{request.protocol}#{request.host_with_port}#{path}"
      end
    end
  end
end
