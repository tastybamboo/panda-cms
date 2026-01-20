# frozen_string_literal: true

module Panda
  module CMS
    # Text component for editable plain text content
    # @param key [Symbol] The key to use for the text component
    # @param text [String] The default text to display
    # @param editable [Boolean] If the text is editable or not (defaults to true)
    class TextComponent < Panda::Core::Base
      KIND = "plain_text"

      attr_reader :key, :text, :editable

      def initialize(key: :text_component, text: "Lorem ipsum...", editable: true, **attrs)
        @key = key
        @text = text
        @editable = editable
        super(**attrs)
      end

      def before_render
        prepare_content
      end

      def call
        return unless @content

        # Russian doll caching: Cache component output at block_content level
        # Only cache in non-editable mode (public-facing pages)
        if should_cache?
          raw cache_component_output
        else
          render_content
        end
      rescue => e
        handle_error(e)
      end

      private

      attr_accessor :plain_text

      def prepare_content
        @editable_state = @editable && is_editable_context?

        block = find_block
        return false if block.nil?

        find_block_content(block)
        @plain_text = @block_content_obj&.content.to_s

        if @editable_state
          setup_editable_content(@block_content_obj)
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
        @block_content_obj = block.block_contents.find_by(panda_cms_page_id: Current.page.id)
      end

      def setup_editable_content(block_content)
        @content = @plain_text
        @block_content_id = block_content&.id
      end

      def element_attrs
        attrs = @attrs.merge(id: element_id)

        if @editable_state
          attrs[:contenteditable] = "plaintext-only"
          attrs[:data] = {
            "editable-kind": "plain_text",
            "editable-page-id": Current.page.id,
            "editable-block-content-id": @block_content_id
          }
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
        page_id = Current.page&.id.to_s

        # Check for session-based editing (preferred, more secure)
        editing_page_id = view_context.session[:panda_cms_editing_page_id]
        editing_expires_at = view_context.session[:panda_cms_editing_expires_at]

        session_valid = editing_page_id == page_id &&
          editing_expires_at.present? &&
          Time.parse(editing_expires_at) > Time.current

        # Fall back to URL param for backwards compatibility (will be removed in future)
        embed_id = view_context.params[:embed_id].to_s
        url_param_valid = embed_id.present? && embed_id == page_id

        session_valid || url_param_valid
      end

      def handle_error(_error)
        if !Rails.env.production? || defined?(Sentry)
          raise Panda::CMS::MissingBlockError, "Block with key #{@key} not found for page #{Current.page.title}"
        end

        false
      end

      def should_cache?
        !@editable_state &&
          Panda::CMS.config.performance.dig(:fragment_caching, :enabled) != false &&
          @block_content_obj.present?
      end

      def cache_component_output
        cache_key = cache_key_for_component
        expires_in = Panda::CMS.config.performance.dig(:fragment_caching, :expires_in) || 1.hour

        Rails.cache.fetch(cache_key, expires_in: expires_in) do
          render_content_to_string
        end.html_safe
      end

      def cache_key_for_component
        "panda_cms/text_component/#{@block_content_obj.cache_key_with_version}/#{@key}"
      end

      def render_content
        content_tag(:span, raw(@content.html_safe), **element_attrs)
      end

      def render_content_to_string
        view_context.content_tag(:span, @content.html_safe, **element_attrs)
      end
    end
  end
end
