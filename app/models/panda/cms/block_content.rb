# frozen_string_literal: true

module Panda
  module CMS
    class BlockContent < ApplicationRecord
      include ::Panda::Editor::Content

      self.table_name = "panda_cms_block_contents"

      belongs_to :page, foreign_key: :panda_cms_page_id, class_name: "Panda::CMS::Page", touch: true
      belongs_to :block, foreign_key: :panda_cms_block_id, class_name: "Panda::CMS::Block"

      validates :block, presence: true, uniqueness: {scope: :page}

      after_save :refresh_page_cached_timestamp
      after_destroy :refresh_page_cached_timestamp

      store_accessor :content, [], prefix: true
      store_accessor :cached_content, [], prefix: true

      private

      def refresh_page_cached_timestamp
        page&.refresh_last_updated_at!
      end
    end
  end
end
