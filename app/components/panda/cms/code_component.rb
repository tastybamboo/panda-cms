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
        # Russian doll caching: Cache component output at block_content level
        # Only cache in non-editable mode (public-facing pages)
        if should_cache?
          raw cache_component_output.to_s.html_safe
        else
          render_content
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
        block.block_contents.find_by(panda_cms_page_id: Current.page.id)
      end

      def render_editable_view
        div(class: "code-component-wrapper mb-4", data: {controller: "inline-code-editor", inline_code_editor_page_id_value: Current.page.id, inline_code_editor_block_content_id_value: @block_content_id}) do
          # Tab Navigation
          div(class: "border-b border-gray-200 bg-white") do
            nav(class: "-mb-px flex space-x-4 px-4", "aria-label": "Tabs") do
              button(type: "button",
                data: {inline_code_editor_target: "previewTab", action: "click->inline-code-editor#showPreview"},
                class: "border-primary text-primary whitespace-nowrap border-b-2 py-2 px-1 text-sm font-medium") do
                plain "Preview"
              end
              button(type: "button",
                data: {inline_code_editor_target: "codeTab", action: "click->inline-code-editor#showCode"},
                class: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 whitespace-nowrap border-b-2 py-2 px-1 text-sm font-medium") do
                plain "Code"
              end
            end
          end

          # Preview View
          div(data: {inline_code_editor_target: "previewView"}, class: "mt-2") do
            div(**preview_attrs) { raw(@code_content.to_s.html_safe) }
          end

          # Code Editor View
          div(data: {inline_code_editor_target: "codeView"}, class: "mt-2 hidden bg-white p-4 border border-gray-200") do
            textarea(
              data: {inline_code_editor_target: "codeInput"},
              class: "w-full h-64 p-3 font-mono text-sm border border-gray-300 rounded focus:ring-primary focus:border-primary",
              placeholder: "Enter your HTML/embed code here..."
            ) { raw(@code_content.to_s) }

            div(class: "mt-3 flex justify-end space-x-2") do
              button(type: "button",
                data: {action: "click->inline-code-editor#saveCode"},
                class: "inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500") do
                plain "💾 Save Code"
              end
            end

            div(data: {inline_code_editor_target: "saveMessage"}, class: "hidden mt-2")
          end
        end
      end

      def preview_attrs
        {
          class: "p-4 border border-dashed border-gray-300 bg-gray-50 min-h-32"
        }
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
        @editable && is_embedded? && Current.user&.admin?
      end

      def is_embedded?
        # Security: Verify embed_id matches the current page being edited
        # This prevents unauthorized editing by ensuring the embed_id in the URL
        # matches the actual page ID from Current.page
        view_context.params[:embed_id].present? &&
          Current.page&.id.to_s == view_context.params[:embed_id].to_s
      end

      def handle_error(error)
        Rails.logger.error "CodeComponent error: #{error.message}"
        Rails.logger.error error.backtrace.join("\n")

        if Rails.env.production?
          false
        else
          div(class: "p-4 bg-red-50 border border-red-200 rounded") do
            p(class: "text-red-800 font-semibold") { "CodeComponent Error" }
            p(class: "text-red-600 text-sm") { error.message }
          end
        end
      end

      def render_content
        if @editable_state
          render_editable_view
        else
          raw(@code_content.to_s.html_safe)
        end
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
        "panda_cms/code_component/#{@block_content_obj.cache_key_with_version}/#{@key}"
      end

      def render_content_to_string
        # For code component, we just return the raw HTML content
        @code_content.to_s
      end

      class BlockError < StandardError; end
    end
  end
end
