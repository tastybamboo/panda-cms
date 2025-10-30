# frozen_string_literal: true

module Panda
  module CMS
    # Text component for editable plain text content
    # @param key [Symbol] The key to use for the text component
    # @param text [String] The default text to display
    # @param editable [Boolean] If the text is editable or not (defaults to true)
    class TextComponent < Panda::Core::Base
      KIND = "plain_text"

      prop :key, Symbol, default: :text_component
      prop :text, String, default: "Lorem ipsum..."
      prop :editable, _Boolean, default: true

      attr_accessor :plain_text

      def view_template
        return unless @content

        span(**element_attrs) { unsafe_raw(@content) }
      rescue => e
        handle_error(e)
      end

      def before_template
        prepare_content
      end

      private

      def prepare_content
        @editable_state = @editable && is_editable_context?

        block = find_block
        return false if block.nil?

        block_content = find_block_content(block)
        @plain_text = block_content&.content.to_s

        if @editable_state
          setup_editable_content(block_content)
        else
          @content = prepare_content_for_display(@plain_text)
        end
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

      def setup_editable_content(block_content)
        @content = @plain_text
        @block_content_id = block_content&.id
      end

      def element_attrs
        attrs = @attrs.merge(id: element_id)

        if @editable_state
          attrs.merge!(
            contenteditable: "plaintext-only",
            data: {
              "editable-kind": "plain_text",
              "editable-page-id": Current.page.id,
              "editable-block-content-id": @block_content_id
            }
          )
        end

        attrs
      end

      def element_id
        @editable_state ? "editor-#{@block_content_id}" : "text-#{@key.to_s.dasherize}"
      end

      def prepare_content_for_display(content)
        # Replace \n characters with <br> tags
        content.gsub("\n", "<br>")
      end

      def is_editable_context?
        helpers.params[:embed_id].present? && helpers.params[:embed_id] == Current.page.id
      end

      def handle_error(error)
        if !Rails.env.production? || defined?(Sentry)
          raise Panda::CMS::MissingBlockError, "Block with key #{@key} not found for page #{Current.page.title}"
        end

        false
      end
    end
  end
end
