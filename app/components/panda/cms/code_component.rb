# frozen_string_literal: true

module Panda
  module CMS
    # Code component for editable HTML/code content
    # @param key [Symbol] The key to use for the code component
    # @param text [String] The default text to display
    # @param editable [Boolean] If the code is editable or not (defaults to true)
    class CodeComponent < Panda::Core::Base
      KIND = "code"

      attr_reader :key, :text, :editable

      def initialize(key: :text_component, text: "", editable: true, **attrs)
        @key = key
        @text = text
        @editable = editable
        raise BlockError, "Key 'code' is not allowed for CodeComponent" if @key == :code
        super(**attrs)
      end

      def before_render
        prepare_content
      end

      # Template is used instead of call method - see code_component.html.erb

      private

      attr_accessor :block_content_obj, :code_content, :block_content_id, :editable_state

      def prepare_content
        @editable_state = component_is_editable?

        block = find_block
        return false if block.nil?

        @block_content_obj = find_block_content(block)
        @code_content = @block_content_obj&.content.to_s
        @block_content_id = @block_content_obj&.id
      end

      def find_block
        Panda::CMS::Block.find_by(
          kind: KIND,
          key: @key,
          panda_cms_template_id: Current.page.panda_cms_template_id
        )
      end

      def find_block_content(block)
        # Try to get from preloaded cache first (eliminates N+1 query)
        Current.block_content_for(@key) || block.block_contents.find_by(panda_cms_page_id: Current.page.id)
      end

      def component_is_editable?
        # TODO: Permissions
        @editable && is_embedded?
      end

      def is_embedded?
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

      def handle_error(error)
        Rails.logger.error "CodeComponent error: #{error.message}"
        Rails.logger.error error.backtrace.join("\n")

        if Rails.env.production?
          false
        else
          content_tag(:div, class: "p-4 bg-red-50 border border-red-200 rounded") do
            concat(content_tag(:p, "CodeComponent Error", class: "text-red-800 font-semibold"))
            concat(content_tag(:p, error.message, class: "text-red-600 text-sm"))
          end
        end
      end

      def cache_component_output
        cache_key = cache_key_for_component
        expires_in = Panda::CMS.config.performance.dig(:fragment_caching, :expires_in) || 1.hour

        Rails.cache.fetch(cache_key, expires_in: expires_in) do
          render_content_to_string
        end.html_safe
      end

      def cache_key_for_component
        "panda_cms/code_component/#{@block_content_obj.cache_key_with_version}/#{@key}"
      end

      def render_content_to_string
        # For code component, we just return the raw HTML content
        @code_content.to_s
      end

      public

      # Helper method for template to decide whether to cache
      def should_cache?
        !@editable_state &&
          Panda::CMS.config.performance.dig(:fragment_caching, :enabled) != false &&
          @block_content_obj.present?
      end

      # Helper method for template to get cached output
      def cached_output
        cache_component_output
      end

      class BlockError < StandardError; end
    end
  end
end
