# frozen_string_literal: true

module Panda
  module CMS
    class SocialSharingComponent < Panda::CMS::Base
      attr_reader :title, :url, :label, :heading_class

      def initialize(title:, url:, label: "Share", heading_class: "text-sm font-semibold uppercase tracking-wider text-gray-500 mb-3")
        @title = title
        @url = url
        @label = label
        @heading_class = heading_class
        super()
      end

      def render?
        networks.any?
      end

      def networks
        @networks ||= Rails.cache.fetch("panda_cms:social_sharing:enabled_networks", expires_in: 1.minute) do
          Panda::CMS::SocialSharingNetwork.enabled.to_a
        end
      end
    end
  end
end
