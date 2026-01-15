# frozen_string_literal: true

module Panda
  module CMS
    class BlockContent < ApplicationRecord
      include ::Panda::Editor::Content

      self.table_name = "panda_cms_block_contents"

      belongs_to :page, foreign_key: :panda_cms_page_id, class_name: "Panda::CMS::Page", touch: true
      belongs_to :block, foreign_key: :panda_cms_block_id, class_name: "Panda::CMS::Block"

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
