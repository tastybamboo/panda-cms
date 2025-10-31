# frozen_string_literal: true

module Panda
  module CMS
    # Code component for editable HTML/code content
    # @param key [Symbol] The key to use for the code component
    # @param text [String] The default text to display
    # @param editable [Boolean] If the code is editable or not (defaults to true)
    class CodeComponent < Panda::Core::Base
      KIND = "code"

      prop :key, Symbol, default: :text_component
      prop :text, String, default: ""
      prop :editable, _Boolean, default: true

      def view_template
        if @editable_state
          div(**element_attrs) { raw(@code_content.to_s.html_safe) }
        else
          raw(@code_content.to_s.html_safe)
        end
      rescue => e
        handle_error(e)
      end

      def before_template
        raise BlockError, "Key 'code' is not allowed for CodeComponent" if @key == :code
        prepare_content
      end

      private

      def prepare_content
        @editable_state = component_is_editable?

        block = find_block
        return false if block.nil?

        block_content = find_block_content(block)
        @code_content = block_content&.content.to_s
        @block_content_id = block_content&.id
      end

      def find_block
        Panda::CMS::Block.find_by(
          kind: KIND,
          key: @key,
          panda_cms_template_id: Current.page.panda_cms_template_id
        )
      end

      def find_block_content(block)
        block.block_contents.find_by(panda_cms_page_id: Current.page.id)
      end

      def element_attrs
        {
          id: "editor-#{@block_content_id}",
          contenteditable: "plaintext-only",
          class: "block bg-yellow-50 font-mono text-xs p-2 border-2 border-yellow-700",
          style: "white-space: pre-wrap;",
          data: {
            "editable-kind": "html",
            "editable-page-id": Current.page.id,
            "editable-block-content-id": @block_content_id
          }
        }.merge(@attrs)
      end

      def component_is_editable?
        # TODO: Permissions
        @editable && is_embedded? && Current.user&.admin
      end

      def is_embedded?
        # TODO: Check security on this - embed_id should match something?
        helpers.request.params[:embed_id].present?
      end

      def handle_error(error)
        unless Rails.env.production?
          raise Panda::CMS::MissingBlockError, "Block with key #{@key} not found for page #{Current.page.title}"
        end

        false
      end

      class BlockError < StandardError; end
    end
  end
end
