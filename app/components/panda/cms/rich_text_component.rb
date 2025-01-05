# frozen_string_literal: true

module Panda
  module CMS
    # Text component
    # @param key [Symbol] The key to use for the text component
    # @param text [String] The text to display
    # @param editable [Boolean] If the text is editable or not (defaults to true)
    # @param options [Hash] The options to pass to the content_tag
    class RichTextComponent < ViewComponent::Base
      class ComponentError < StandardError; end

      KIND = "rich_text"

      attr_accessor :editable
      attr_accessor :content
      attr_accessor :options

      def initialize(key: :text_component, text: "Lorem ipsum...", editable: true, **options)
        @key = key
        @text = text
        @options = options || {}
        @editable = editable
      end

      # Check if the element is editable and set up the content
      def before_render
        @editable &&= params[:embed_id].present? && params[:embed_id] == Current.page.id && Current.user.admin?

        block = Panda::CMS::Block.find_by(kind: "rich_text", key: @key, panda_cms_template_id: Current.page.panda_cms_template_id)
        raise ComponentError, "Block not found for key: #{@key}" unless block

        block_content = block.block_contents.find_by(panda_cms_page_id: Current.page.id)
        if block_content.nil?
          block_content = Panda::CMS::BlockContent.create!(
            block: block,
            panda_cms_page_id: Current.page.id,
            content: ""
          )
        end

        @content = block_content.cached_content || block_content.content
        raise ComponentError, "No content found for block: #{block.id}" if @content.nil?

        @options[:id] = block_content.id

        if @editable
          @options[:data] = {
            page_id: Current.page.id,
            mode: "rich_text"
          }

          # Convert HTML content to EditorJS format if needed
          begin
            editor_content = Panda::CMS::HtmlToEditorJsConverter.convert(@content)
            @content = editor_content
          rescue Panda::CMS::HtmlToEditorJsConverter::ConversionError => e
            raise ComponentError, "Failed to convert content: #{e.message}"
          end
        else
          if @content = JSON.parse(@content)
            begin
              renderer = Panda::CMS::EditorJs::Renderer.new(@content)
              @content = renderer.render.html_safe
            rescue => e
              raise ComponentError, "Failed to render content: #{e.message}"
            end
          else
            @content = @content.html_safe
          end
        end
      rescue ActiveRecord::RecordNotFound => e
        raise ComponentError, "Database record not found: #{e.message}"
      rescue ActiveRecord::RecordInvalid => e
        raise ComponentError, "Invalid record: #{e.message}"
      rescue => e
        raise ComponentError, "Component error: #{e.message}"
      end

      # Only render the component if there is some content set, or if the component is editable
      def render?
        @content.present? || @editable
      end
    end
  end
end
