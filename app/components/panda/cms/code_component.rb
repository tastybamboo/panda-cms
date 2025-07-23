# frozen_string_literal: true

module Panda
  module CMS
    # Text component
    # @param key [Symbol] The key to use for the text component
    # @param text [String] The text to display
    # @param editable [Boolean] If the text is editable or not (defaults to true)
    # @param options [Hash] The options to pass to the content_tag
    class CodeComponent < ViewComponent::Base
      KIND = "code"

      def initialize(key: :text_component, text: "", editable: true, **options)
        @key = key
        @text = text
        @options = options || {}
        @options[:id] ||= "code-#{key.to_s.dasherize}"
        @editable = editable

        raise BlockError, "Key 'code' is not allowed for CodeComponent" if key == :code
      end

      def call
        # TODO: For the non-editable version, grab this from a cache or similar?
        block = Panda::CMS::Block.find_by(kind: KIND, key: @key,
          panda_cms_template_id: Current.page.panda_cms_template_id)

        if block.nil?
          unless Rails.env.production?
            raise Panda::CMS::MissingBlockError, "Block with key #{@key} not found for page #{Current.page.title}"
          end

          return false
        end

        block_content = block.block_contents.find_by(panda_cms_page_id: Current.page.id)
        code_content = block_content&.content.to_s

        if component_is_editable?
          @options[:contenteditable] = "plaintext-only"
          @options[:data] = {
            "editable-kind": "html",
            "editable-page-id": Current.page.id,
            "editable-block-content-id": block_content&.id
          }
          @options[:class] = "block bg-yellow-50 font-mono text-xs p-2 border-2 border-yellow-700"
          @options[:style] = "white-space: pre-wrap;"

          @options[:id] = "editor-#{block_content&.id}"

          # TODO: Switch between the HTML and the preview?
          content_tag(:div, code_content, @options, true)
        else
          code_content.html_safe
        end
      end

      def component_is_editable?
        # TODO: Permissions
        @editable && is_embedded? && Current.user&.admin
      end

      def is_embedded?
        # TODO: Check security on this - embed_id should match something?
        request.params[:embed_id].present?
      end
    end
  end
end
