# frozen_string_literal: true

module Panda
  module CMS
    class BlockContent < ApplicationRecord
      include ::Panda::Editor::Content

      self.table_name = "panda_cms_block_contents"

      belongs_to :page, foreign_key: :panda_cms_page_id, class_name: "Panda::CMS::Page", touch: true
      belongs_to :block, foreign_key: :panda_cms_block_id, class_name: "Panda::CMS::Block"
      has_many :block_images,
        class_name: "Panda::CMS::BlockImage",
        foreign_key: :panda_cms_block_content_id,
        dependent: :destroy

      accepts_nested_attributes_for :block_images,
        allow_destroy: true,
        reject_if: proc { |attrs| attrs["file"].blank? && attrs["id"].blank? }

      validates :block, presence: true, uniqueness: {scope: :page}
      validate :block_template_matches_page_template

      # Remove orphaned block_contents where the block's template doesn't match the page's template
      # This can happen when a page's template is changed after block_contents were created
      def self.cleanup_orphaned
        orphaned = joins(:block, :page)
          .where.not("panda_cms_blocks.panda_cms_template_id = panda_cms_pages.panda_cms_template_id")

        count = orphaned.count
        orphaned.destroy_all
        count
      end

      after_save :refresh_page_cached_timestamp
      after_destroy :refresh_page_cached_timestamp

      store_accessor :content, [], prefix: true
      store_accessor :cached_content, [], prefix: true

      # Get the first/primary image for blocks with a single image
      # @return [Panda::CMS::BlockImage, nil]
      def primary_image
        block_images.first
      end

      # Find a specific image by its key
      # @param key [String, Symbol] The key identifier
      # @return [Panda::CMS::BlockImage, nil]
      def find_image_by_key(key)
        block_images.find_by(key: key.to_s)
      end

      # Check if this block has any images attached
      # @return [Boolean]
      def has_images?
        block_images.any?
      end

      private

      def block_template_matches_page_template
        return if block.nil? || page.nil?
        return if block.panda_cms_template_id == page.panda_cms_template_id

        errors.add(:block, "must belong to the same template as the page")
      end

      def refresh_page_cached_timestamp
        page&.refresh_last_updated_at!
      end
    end
  end
end
