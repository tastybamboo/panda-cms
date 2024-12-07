# frozen_string_literal: true

module Panda
  module CMS
    # Text component
    # @param key [Symbol] The key to use for the text component
    # @param text [String] The text to display
    # @param editable [Boolean] If the text is editable or not (defaults to true)
    # @param options [Hash] The options to pass to the content_tag
    class RichTextComponent < ViewComponent::Base
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
        block_content = block.block_contents.find_by(panda_cms_page_id: Current.page.id)
        if block_content.nil?
          block_content = Panda::CMS::BlockContent.create(block: block, panda_cms_page_id: Current.page.id, content: "")
        end

        @content = block_content.cached_content || block_content.content
        @options[:id] = block_content.id

        if @editable
          @options[:data] = {
            page_id: Current.page.id,
            mode: "rich_text"
          }

          @content = block_content.content
        elsif @content.is_a?(Hash)
          renderer = Panda::CMS::EditorJs::Renderer.new(@content)
          @content = renderer.render
        else
          @content = @content.html_safe
        end
      rescue => e
        if Rails.env.production?
          Sentry.capture_exception(e) if defined?(Sentry)
        else
          raise e
        end
        false
      end

      # Only render the component if there is some content set, or if the component is editable
      def render?
        @content.present? || @editable
      end
    end
  end
end
