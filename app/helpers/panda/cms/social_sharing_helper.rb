# frozen_string_literal: true

module Panda
  module CMS
    # Helper for rendering social sharing buttons from all enabled networks.
    #
    # Include this helper in your post layout or any view to display
    # sharing buttons configured in the CMS admin.
    #
    # @example In your post layout
    #   <%= panda_social_sharing(title: @post.title, url: request.base_url + post_path(@post)) %>
    #
    module SocialSharingHelper
      def panda_social_sharing(title:, url:, label: "Share", heading_class: nil)
        options = {title: title, url: url, label: label}
        options[:heading_class] = heading_class if heading_class
        render Panda::CMS::SocialSharingComponent.new(**options)
      end
    end
  end
end
