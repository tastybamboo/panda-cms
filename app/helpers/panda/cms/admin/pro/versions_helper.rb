# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      module Pro
        module VersionsHelper
          # Compare two EditorJS content structures and return diff metadata
          # @param version_content [Hash] The older version content
          # @param current_content [Hash] The current version content
          # @return [Hash] Metadata about added/removed/changed blocks
          def diff_blocks(version_content, current_content)
            return {added: [], removed: [], unchanged: []} unless version_content.is_a?(Hash) && current_content.is_a?(Hash)

            version_blocks = version_content.dig("blocks") || []
            current_blocks = current_content.dig("blocks") || []

            # Simple comparison: blocks with same content are unchanged
            version_texts = version_blocks.map { |b| block_to_text(b) }
            current_texts = current_blocks.map { |b| block_to_text(b) }

            removed = version_blocks.select.with_index { |block, i| !current_texts.include?(version_texts[i]) }
            added = current_blocks.select.with_index { |block, i| !version_texts.include?(current_texts[i]) }
            unchanged = version_blocks.select.with_index { |block, i| current_texts.include?(version_texts[i]) }

            {
              added: added,
              removed: removed,
              unchanged: unchanged
            }
          end

          # Check if a block exists in the other version
          def block_in_version?(block, version_blocks)
            return false unless version_blocks.is_a?(Array)

            block_text = block_to_text(block)
            version_blocks.any? { |vb| block_to_text(vb) == block_text }
          end

          private

          def block_to_text(block)
            return "" unless block.is_a?(Hash)

            case block["type"]
            when "paragraph", "header"
              block.dig("data", "text").to_s
            when "list"
              block.dig("data", "items")&.join(" ") || ""
            when "quote"
              block.dig("data", "text").to_s
            else
              block["type"].to_s
            end
          end
        end
      end
    end
  end
end
