# frozen_string_literal: true

module Panda
  module CMS
    class Current < Panda::Core::Current
      # CMS-specific attributes
      attribute :page
      attribute :block_contents_cache

      # Preload all block contents for the current page into a cache hash
      # This eliminates N+1 queries when multiple components render on a page
      def self.preload_block_contents!
        return unless page&.id

        # Build a hash keyed by block key for O(1) lookup
        self.block_contents_cache = page.block_contents.each_with_object({}) do |bc, hash|
          hash[bc.block&.key] = bc
        end
      end

      # Get block content for a given block key (O(1) lookup)
      def self.block_content_for(key)
        block_contents_cache&.[](key)
      end
    end
  end
end
