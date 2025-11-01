# frozen_string_literal: true

module Panda
  module CMS
    module Pro
      class ContentChange < ApplicationRecord
        self.table_name = "panda_cms_pro_content_changes"

        belongs_to :content_version, class_name: "Panda::CMS::Pro::ContentVersion",
                   foreign_key: :panda_cms_pro_content_version_id

        validates :panda_cms_pro_content_version_id, presence: true
        validates :change_type, presence: true

        enum :change_type, {
          addition: "addition",
          deletion: "deletion",
          modification: "modification",
          callout: "callout",
          citation: "citation"
        }

        scope :for_section, ->(section) { where(section_identifier: section) }
        scope :recent, -> { order(created_at: :desc) }

        def description
          case change_type
          when "addition"
            "Added content to #{section_identifier || 'document'}"
          when "deletion"
            "Removed content from #{section_identifier || 'document'}"
          when "modification"
            "Modified #{section_identifier || 'content'}"
          when "callout"
            "Updated callout in #{section_identifier || 'document'}"
          when "citation"
            "Updated citation in #{section_identifier || 'document'}"
          else
            "Changed #{section_identifier || 'content'}"
          end
        end

        def change_stats
          old_length = old_content&.length || 0
          new_length = new_content&.length || 0

          {
            old_length: old_length,
            new_length: new_length,
            diff: new_length - old_length,
            type: change_type
          }
        end
      end
    end
  end
end
