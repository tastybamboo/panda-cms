# frozen_string_literal: true

module Panda
  module CMS
    class Block < ApplicationRecord
      self.table_name = "panda_cms_blocks"

      belongs_to :template, foreign_key: :panda_cms_template_id, class_name: "Panda::CMS::Template"
      has_many :block_contents, foreign_key: :panda_cms_block_id, class_name: "Panda::CMS::BlockContent",
        dependent: :destroy

      validates :name, presence: true
      validates :key, presence: true, uniqueness: {scope: :panda_cms_template_id, case_sensitive: false}
      validates :kind, presence: true

      enum :kind, {
        plain_text: "plain_text",
        rich_text: "rich_text",
        image: "image",
        video: "video",
        audio: "audio",
        file: "file",
        code: "code",
        iframe: "iframe",
        quote: "quote"
      }
    end
  end
end
