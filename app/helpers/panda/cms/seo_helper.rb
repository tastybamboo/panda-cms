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

        # Open Graph image
        if resource.og_image.attached?
          og_image_url = url_for(resource.og_image.variant(:og_share))
          tags << tag.meta(property: "og:image", content: og_image_url)
          tags << tag.meta(property: "og:image:width", content: "1200")
          tags << tag.meta(property: "og:image:height", content: "630")
        end

        # Twitter Card tags (with fallback to OG)
        tags << tag.meta(name: "twitter:card", content: "summary_large_image")
        tags << tag.meta(name: "twitter:title", content: resource.effective_og_title)
        tags << tag.meta(name: "twitter:description", content: resource.effective_og_description) if resource.effective_og_description.present?

        # Twitter image (same as OG)
        if resource.og_image.attached?
          tags << tag.meta(name: "twitter:image", content: url_for(resource.og_image.variant(:og_share)))
        end

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
