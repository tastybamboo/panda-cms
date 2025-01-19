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
            content: empty_editor_js_content
          )
        end

        raw_content = block_content.cached_content || block_content.content
        @content = raw_content.presence || empty_editor_js_content
        @options[:id] = block_content.id

        # Debug log the content
        Rails.logger.debug("RichTextComponent content before processing: #{@content.inspect}")

        if @editable
          @options[:data] = {
            page_id: Current.page.id,
            mode: "rich_text"
          }

          # For editable mode, always ensure we have a valid EditorJS structure
          @content = if @content.blank? || @content == "{}"
            empty_editor_js_content
          else
            begin
              if @content.is_a?(String)
                # Try to parse as JSON first
                begin
                  parsed = JSON.parse(@content)
                  if valid_editor_js_content?(parsed)
                    # Ensure the content is properly structured
                    {
                      "time" => parsed["time"] || Time.current.to_i * 1000,
                      "blocks" => parsed["blocks"].map { |block|
                        {
                          "type" => block["type"],
                          "data" => block["data"].merge(
                            "text" => block["data"]["text"].to_s.presence || ""
                          ),
                          "tunes" => block["tunes"]
                        }.compact
                      },
                      "version" => parsed["version"] || "2.28.2"
                    }
                  else
                    # If not valid EditorJS, try to convert from HTML
                    begin
                      editor_content = Panda::CMS::HtmlToEditorJsConverter.convert(@content)
                      if valid_editor_js_content?(editor_content)
                        editor_content
                      else
                        empty_editor_js_content
                      end
                    rescue Panda::CMS::HtmlToEditorJsConverter::ConversionError => e
                      Rails.logger.error("HTML conversion error: #{e.message}")
                      empty_editor_js_content
                    end
                  end
                rescue JSON::ParserError => e
                  Rails.logger.error("JSON parse error: #{e.message}")
                  # Try to convert from HTML
                  begin
                    editor_content = Panda::CMS::HtmlToEditorJsConverter.convert(@content)
                    if valid_editor_js_content?(editor_content)
                      editor_content
                    else
                      empty_editor_js_content
                    end
                  rescue Panda::CMS::HtmlToEditorJsConverter::ConversionError => e
                    Rails.logger.error("HTML conversion error: #{e.message}")
                    empty_editor_js_content
                  end
                end
              else
                # If it's not a string, assume it's already in the correct format
                valid_editor_js_content?(@content) ? @content : empty_editor_js_content
              end
            rescue => e
              Rails.logger.error("Content processing error: #{e.message}\nContent: #{@content.inspect}")
              empty_editor_js_content
            end
          end
        else
          # For non-editable mode, handle content display
          @content = if @content.blank? || @content == "{}"
            "<p></p>".html_safe
          else
            begin
              # Try to parse as JSON if it looks like EditorJS format
              if @content.is_a?(String) && @content.strip.match?(/^\{.*"blocks":\s*\[.*\].*\}$/m)
                parsed_content = JSON.parse(@content)
                if valid_editor_js_content?(parsed_content)
                  # Check if it's just an empty paragraph
                  if parsed_content["blocks"].length == 1 &&
                      parsed_content["blocks"][0]["type"] == "paragraph" &&
                      parsed_content["blocks"][0]["data"]["text"].blank?
                    "<p></p>".html_safe
                  else
                    renderer = Panda::CMS::EditorJs::Renderer.new(parsed_content)
                    rendered = renderer.render
                    rendered.presence&.html_safe || "<p></p>".html_safe
                  end
                else
                  process_html(@content)
                end
              else
                process_html(@content)
              end
            rescue JSON::ParserError
              process_html(@content)
            rescue => e
              Rails.logger.error("RichTextComponent render error: #{e.message}\nContent: #{@content.inspect}")
              "<p></p>".html_safe
            end
          end
        end
      rescue ActiveRecord::RecordNotFound => e
        raise ComponentError, "Database record not found: #{e.message}"
      rescue ActiveRecord::RecordInvalid => e
        raise ComponentError, "Invalid record: #{e.message}"
      rescue => e
        Rails.logger.error("RichTextComponent error: #{e.message}\nContent: #{@content.inspect}")
        @content = @editable ? empty_editor_js_content : "<p></p>".html_safe
        nil
      end

      private

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

      def process_html(content)
        return "<p></p>".html_safe if content.blank?

        # If it's already HTML, just return it
        if content.match?(/<[^>]+>/)
          content.html_safe
        else
          # Wrap plain text in paragraph tags
          "<p>#{content}</p>".html_safe
        end
      end

      # Only render the component if there is some content set, or if the component is editable
      def render?
        true # Always render, we'll show empty content if needed
      end
    end
  end
end
