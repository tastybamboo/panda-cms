# frozen_string_literal: true

module Panda
  module CMS
    # Rich text component for EditorJS-based content editing
    # @param key [Symbol] The key to use for the rich text component
    # @param text [String] The default text to display
    # @param editable [Boolean] If the text is editable or not (defaults to true)
    class RichTextComponent < Panda::Core::Base
      class ComponentError < StandardError; end

      KIND = "rich_text"

      attr_reader :key, :text, :editable
      attr_accessor :content, :block_content_id

      def initialize(key: :text_component, text: "Lorem ipsum...", editable: true, **attrs)
        @key = key
        @text = text
        @editable = editable
        super()
      end

      def before_render
        setup_editability
        load_block_content
        prepare_content
      rescue ActiveRecord::RecordNotFound => e
        handle_error(ComponentError.new("Database record not found: #{e.message}"))
      rescue ActiveRecord::RecordInvalid => e
        handle_error(ComponentError.new("Invalid record: #{e.message}"))
      rescue => e
        handle_error(e)
      end

      private

      def setup_editability
        page_id = Current.page&.id.to_s

        # In test/component environments, view_context might not have full request context
        unless view_context.respond_to?(:params) && view_context.respond_to?(:request) && view_context.respond_to?(:session)
          @editable_state = false
          return
        end

        # Editing requires:
        # 1. embed_id param matching the page (indicates editor iframe context)
        # 2. Being loaded in an iframe (Sec-Fetch-Dest header check)
        # 3. Referer from our admin area (same-origin security)
        embed_id = view_context.params[:embed_id].to_s
        is_iframe_request = view_context.request.headers["Sec-Fetch-Dest"] == "iframe"

        # Check referer is from our admin area (same domain)
        referer = view_context.request.headers["Referer"].to_s
        request_host = view_context.request.host
        admin_path = Panda::Core.config.admin_path
        referer_valid = referer.present? &&
          URI.parse(referer).host == request_host &&
          referer.include?(admin_path)

        # Must have embed_id AND be in iframe AND from our admin to enable editing
        unless embed_id.present? && embed_id == page_id && is_iframe_request && referer_valid
          @editable_state = false
          return
        end

        # Validate with session-based check (additional security layer)
        editing_page_id = view_context.session[:panda_cms_editing_page_id]
        editing_expires_at = view_context.session[:panda_cms_editing_expires_at]

        session_valid = editing_page_id == page_id &&
          editing_expires_at.present? &&
          Time.parse(editing_expires_at) > Time.current

        # All checks passed - enable editing
        @editable_state = @editable && session_valid
      end

      def load_block_content
        block = Panda::CMS::Block.find_by(
          kind: KIND,
          key: @key,
          panda_cms_template_id: Current.page.panda_cms_template_id
        )
        raise ComponentError, "Block not found for key: #{@key}" unless block

        @block_content = block.block_contents.find_by(panda_cms_page_id: Current.page.id)

        if @block_content.nil?
          @block_content = Panda::CMS::BlockContent.create!(
            block: block,
            panda_cms_page_id: Current.page.id,
            content: empty_editor_js_content
          )
        end

        @block_content_id = @block_content.id
        # For editing, use content (EditorJS JSON) directly
        # For display, prefer cached_content (pre-rendered HTML) for speed
        raw_content = if @editable_state
          @block_content.content
        else
          @block_content.cached_content || @block_content.content
        end
        @content = raw_content.presence || empty_editor_js_content
      end

      def prepare_content
        if @editable_state
          prepare_editable_content
        else
          prepare_display_content
        end
      end

      def prepare_editable_content
        @editor_content = if @content.blank? || @content == "{}"
          empty_editor_js_content
        else
          process_content_for_editor(@content)
        end

        @encoded_data = Base64.strict_encode64(@editor_content.to_json)
      rescue => e
        Rails.logger.error("Content processing error: #{e.message}\nContent: #{@content.inspect}")
        @editor_content = empty_editor_js_content
        @encoded_data = Base64.strict_encode64(@editor_content.to_json)
      end

      def prepare_display_content
        @rendered_content = if @content.blank? || @content == "{}"
          "<p></p>"
        else
          render_content_for_display(@content)
        end
      rescue => e
        Rails.logger.error("RichTextComponent render error: #{e.message}\nContent: #{@content.inspect}")
        @rendered_content = "<p></p>"
      end

      def process_content_for_editor(content)
        parsed = if content.is_a?(String)
          JSON.parse(content)
        else
          content
        end

        if valid_editor_js_content?(parsed)
          normalize_editor_content(parsed)
        else
          convert_html_to_editor_js(content)
        end
      rescue JSON::ParserError
        convert_html_to_editor_js(content)
      end

      def normalize_editor_content(parsed)
        {
          "time" => parsed["time"] || Time.current.to_i * 1000,
          "blocks" => (parsed["blocks"] || []).map { |block| normalize_block(block) },
          "version" => parsed["version"] || "2.28.2"
        }
      end

      def normalize_block(block)
        case block["type"]
        when "paragraph"
          block.merge("data" => block["data"].merge("text" => block["data"]["text"].to_s.presence || ""))
        when "header"
          block.merge("data" => block["data"].merge(
            "text" => block["data"]["text"].to_s.presence || "",
            "level" => block["data"]["level"].to_i
          ))
        when "list"
          # Handle both simple string items and nested list format (objects with content/items)
          normalized_items = (block["data"]["items"] || []).map do |item|
            if item.is_a?(Hash)
              # Nested list format: {"content": "text", "items": [...]}
              item
            else
              # Simple string format
              item.to_s.presence || ""
            end
          end
          block.merge("data" => block["data"].merge("items" => normalized_items))
        else
          block
        end
      end

      def convert_html_to_editor_js(content)
        editor_content = Panda::Editor::HtmlToEditorJsConverter.convert(content.to_s)
        valid_editor_js_content?(editor_content) ? editor_content : empty_editor_js_content
      rescue Panda::Editor::HtmlToEditorJsConverter::ConversionError => e
        Rails.logger.error("HTML conversion error: #{e.message}")
        empty_editor_js_content
      end

      def render_content_for_display(content)
        # Try to parse as JSON if it looks like EditorJS format
        if content.is_a?(String) && content.strip.match?(/^\{.*"blocks":\s*\[.*\].*\}$/m)
          parsed_content = JSON.parse(content)
          if valid_editor_js_content?(parsed_content)
            render_editor_js_content(parsed_content)
          else
            process_html_content(content)
          end
        else
          process_html_content(content)
        end
      rescue JSON::ParserError
        process_html_content(content)
      end

      def render_editor_js_content(parsed_content)
        # Check if it's just an empty paragraph
        if parsed_content["blocks"].length == 1 &&
            parsed_content["blocks"][0]["type"] == "paragraph" &&
            parsed_content["blocks"][0]["data"]["text"].blank?
          "<p></p>"
        else
          renderer = Panda::Editor::Renderer.new(parsed_content)
          rendered = renderer.render
          rendered.presence || "<p></p>"
        end
      end

      def process_html_content(content)
        return "<p></p>" if content.blank?

        # If it's already HTML, return it
        if content.match?(/<[^>]+>/)
          content
        else
          # Wrap plain text in paragraph tags
          "<p>#{content}</p>"
        end
      end

      def element_attrs
        attrs = {class: "panda-cms-content"}

        if @editable_state
          attrs[:id] = "editor-#{@block_content_id}"
          attrs[:data] = {
            "editable-previous-data": @encoded_data,
            "editable-content": @encoded_data,
            "editable-initialized": "false",
            "editable-version": "2.28.2",
            "editable-autosave": "false",
            "editable-tools": '{"paragraph":true,"header":true,"list":true,"quote":true,"table":true}',
            "editable-kind": "rich_text",
            "editable-block-content-id": @block_content_id,
            "editable-page-id": Current.page.id,
            controller: "editor-js",
            "editor-js-initialized-value": "false",
            "editor-js-content-value": @encoded_data
          }
        end

        attrs
      end

      def empty_editor_js_content
        {
          time: Time.current.to_i * 1000,
          blocks: [{type: "paragraph", data: {text: ""}}],
          version: "2.28.2"
        }
      end

      def valid_editor_js_content?(content)
        content.is_a?(Hash) && content["blocks"].is_a?(Array) && content["version"].present?
      rescue
        false
      end

      def handle_error(error)
        Rails.logger.error("RichTextComponent error: #{error.message}\nContent: #{@content.inspect}")

        if @editable_state
          @editor_content = empty_editor_js_content
          @encoded_data = Base64.strict_encode64(@editor_content.to_json)
        else
          @rendered_content = "<p></p>"
        end

        nil
      end

      def should_cache?
        !@editable_state &&
          Panda::CMS.config.performance.dig(:fragment_caching, :enabled) != false &&
          @block_content.present?
      end

      def cache_component_output
        cache_key = cache_key_for_component
        expires_in = Panda::CMS.config.performance.dig(:fragment_caching, :expires_in) || 1.hour

        Rails.cache.fetch(cache_key, expires_in: expires_in) do
          render_content_to_string
        end.html_safe
      end

      def cache_key_for_component
        "panda_cms/rich_text_component/#{@block_content.cache_key_with_version}/#{@key}"
      end

      def render_content_to_string
        # Render the component HTML to a string for caching
        helpers.content_tag(:div, @rendered_content.html_safe, class: "panda-cms-content", **element_attrs)
      end

      # Helper method for template to decide whether to cache
      def use_caching?
        should_cache?
      end

      # Helper method for template to get cached output
      def cached_output
        cache_component_output
      end
    end
  end
end
