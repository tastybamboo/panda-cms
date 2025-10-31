# frozen_string_literal: true

class ConvertHtmlContentToEditorJs < ActiveRecord::Migration[7.1]
  def up
    # First, let's check if the converter service exists
    converter_path = Panda::CMS::Engine.root.join("app/services/panda/cms/html_to_editor_js_converter.rb")

    unless File.exist?(converter_path)
      Rails.logger.info "HtmlToEditorJsConverter service not found. Skipping HTML to EditorJS conversion."
      return
    end

    require converter_path

    # Check if we have any existing valid EditorJS content
    existing_editor_js = Panda::CMS::BlockContent.find_each.any? do |block_content|
      valid_editor_js_content?(block_content.content)
    end

    if existing_editor_js
      Rails.logger.warn "Found existing valid EditorJS content. Skipping migration to prevent data loss."
      return
    end

    Rails.logger.info "Starting conversion of HTML content to EditorJS format..."

    # Get all block contents that need conversion
    Panda::CMS::BlockContent.find_each do |block_content|
      next if block_content.content.blank?

      begin
        Rails.logger.info "Converting content for BlockContent ##{block_content.id}"

        # Convert the content
        editor_js_content = Panda::CMS::HtmlToEditorJsConverter.convert(block_content.content)

        # Validate the converted content
        unless valid_editor_js_content?(editor_js_content)
          Rails.logger.error "Skipping BlockContent ##{block_content.id}: Conversion resulted in invalid or empty content"
          next
        end

        # Update the record directly to avoid callbacks
        block_content.update_columns(
          content: editor_js_content,
          updated_at: Time.current
        )

        Rails.logger.info "Successfully converted BlockContent ##{block_content.id}"
      rescue => e
        Rails.logger.error "Failed to convert BlockContent ##{block_content.id}: #{e.message}"
        # Continue with the next record instead of failing the entire migration
      end
    end

    Rails.logger.info "Completed conversion to EditorJS format"
  end

  def down
    Rails.logger.warn "This migration cannot be reversed as it would require original HTML content"
  end

  private

  def valid_editor_js_content?(content)
    return false unless content.is_a?(Hash)
    return false unless content["blocks"].is_a?(Array)
    return false if content["blocks"].empty?

    # Check if there are any non-empty blocks
    content["blocks"].any? do |block|
      next false unless block.is_a?(Hash)
      next false unless block["data"].is_a?(Hash)

      case block["type"]
      when "paragraph"
        block["data"]["text"].present?
      when "header"
        block["data"]["text"].present?
      when "list"
        block["data"]["items"].present? && block["data"]["items"].any?(&:present?)
      when "quote"
        block["data"]["text"].present?
      else
        false
      end
    end
  end
end
