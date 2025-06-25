# frozen_string_literal: true

module Panda
  module CMS
    # Text component
    # @param key [Symbol] The key to use for the text component
    # @param text [String] The text to display
    # @param editable [Boolean] If the text is editable or not (defaults to true)
    # @param options [Hash] The options to pass to the content_tag
    class TextComponent < ViewComponent::Base
      KIND = "plain_text"

      # Allows accessing the plain text of the component directly
      attr_accessor :plain_text

      def initialize(key: :text_component, text: "Lorem ipsum...", editable: true, **options)
        @key = key
        @text = text
        @options = options || {}
        @options[:id] ||= "text-#{key.to_s.dasherize}"
        @editable = editable
      end

      def call
        content_tag(:span, @content, @options, false) # Don't escape the content
      rescue
        if !Rails.env.production? || is_defined?(Sentry)
          raise Panda::CMS::MissingBlockError, "Block with key #{@key} not found for page #{Current.page.title}"
        end

        false
      end

      #
      # Prepares content for display
      #
      # @usage Do not use this when rendering editable content
      def prepare_content_for_display(content)
        # Replace \n characters with <br> tags
        content.gsub("\n", "<br>")
      end

      # Check if the element is editable
      # TODO: Check user permissions
      def before_render
        @editable &&= params[:embed_id].present? && params[:embed_id] == Current.page.id

        block = Panda::CMS::Block.find_by(kind: KIND, key: @key,
          panda_cms_template_id: Current.page.panda_cms_template_id)

        return false if block.nil?

        block_content = block.block_contents.find_by(panda_cms_page_id: Current.page.id)
        plain_text = block_content&.content.to_s
        if @editable
          @options[:contenteditable] = "plaintext-only"
          @options[:data] = {
            "editable-kind": "plain_text",
            "editable-page-id": Current.page.id,
            "editable-block-content-id": block_content&.id
          }

          @options[:id] = "editor-#{block_content&.id}"
          @content = plain_text
        else
          @content = prepare_content_for_display(plain_text)
        end
      end
    end
  end
end
