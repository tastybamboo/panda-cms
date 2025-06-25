# frozen_string_literal: true

module Panda
  module CMS
    class HtmlToEditorJsConverter
      class ConversionError < StandardError; end

      def self.convert(html)
        return {} if html.blank?

        # If it's already in EditorJS format, return as is
        return html if html.is_a?(Hash) && (html["blocks"].present? || html[:blocks].present?)

        begin
          # Parse the HTML content
          doc = Nokogiri::HTML.fragment(html.to_s)
          raise ConversionError, "Failed to parse HTML content" unless doc

          blocks = []
          current_text = ""

          doc.children.each do |node|
            case node.name
            when "h1", "h2", "h3", "h4", "h5", "h6"
              # Add any accumulated text as a paragraph before the header
              if current_text.present?
                blocks << create_paragraph_block(current_text)
                current_text = ""
              end

              blocks << {
                "type" => "header",
                "data" => {
                  "text" => node.text.strip,
                  "level" => node.name[1].to_i
                }
              }
            when "p", "div"
              # Add any accumulated text first
              if current_text.present?
                blocks << create_paragraph_block(current_text)
                current_text = ""
              end

              if node.name == "div"
                # Process div children separately
                node.children.each do |child|
                  case child.name
                  when "h1", "h2", "h3", "h4", "h5", "h6"
                    blocks << {
                      "type" => "header",
                      "data" => {
                        "text" => child.text.strip,
                        "level" => child.name[1].to_i
                      }
                    }
                  when "p"
                    text = process_inline_elements(child)
                    paragraphs = text.split(%r{<br\s*/?>\s*<br\s*/?>}).map(&:strip)
                    paragraphs.each do |paragraph|
                      blocks << create_paragraph_block(paragraph) if paragraph.present?
                    end
                  when "ul", "ol"
                    items = child.css("li").map { |li| process_inline_elements(li) }
                    next if items.empty?

                    blocks << {
                      "type" => "list",
                      "data" => {
                        "style" => (child.name == "ul") ? "unordered" : "ordered",
                        "items" => items
                      }
                    }
                  when "blockquote"
                    blocks << {
                      "type" => "quote",
                      "data" => {
                        "text" => process_inline_elements(child),
                        "caption" => "",
                        "alignment" => "left"
                      }
                    }
                  when "text"
                    text = child.text.strip
                    current_text += text if text.present?
                  end
                end
              else
                # Handle p with nested content
                text = process_inline_elements(node)
                paragraphs = text.split(%r{<br\s*/?>\s*<br\s*/?>}).map(&:strip)
                paragraphs.each do |paragraph|
                  blocks << create_paragraph_block(paragraph) if paragraph.present?
                end
              end
            when "br"
              current_text += "\n\n"
            when "text"
              text = node.text.strip
              current_text += text if text.present?
            when "ul", "ol"
              # Add any accumulated text first
              if current_text.present?
                blocks << create_paragraph_block(current_text)
                current_text = ""
              end

              items = node.css("li").map { |li| process_inline_elements(li) }
              next if items.empty?

              blocks << {
                "type" => "list",
                "data" => {
                  "style" => (node.name == "ul") ? "unordered" : "ordered",
                  "items" => items
                }
              }
            when "blockquote"
              # Add any accumulated text first
              if current_text.present?
                blocks << create_paragraph_block(current_text)
                current_text = ""
              end

              blocks << {
                "type" => "quote",
                "data" => {
                  "text" => process_inline_elements(node),
                  "caption" => "",
                  "alignment" => "left"
                }
              }
            end
          end

          # Add any remaining text
          blocks << create_paragraph_block(current_text) if current_text.present?

          # Return the complete EditorJS structure
          {
            "time" => Time.current.to_i * 1000,
            "blocks" => blocks,
            "version" => "2.28.2"
          }
        rescue => e
          Rails.logger.error "HTML to EditorJS conversion failed: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          raise ConversionError, "Failed to convert HTML to EditorJS format: #{e.message}"
        end
      end

      def self.create_paragraph_block(text)
        {
          "type" => "paragraph",
          "data" => {
            "text" => text.strip
          }
        }
      end

      def self.process_inline_elements(node)
        result = ""
        node.children.each do |child|
          case child.name
          when "br"
            result += "<br>"
          when "text"
            result += child.text
          when "strong", "b"
            result += "<b>#{child.text}</b>"
          when "em", "i"
            result += "<i>#{child.text}</i>"
          when "a"
            href = child["href"]
            text = child.text.strip
            # Handle email links specially
            if href&.start_with?("mailto:")
              email = href.sub("mailto:", "")
              result += "<a href=\"mailto:#{email}\">#{text}</a>"
            else
              result += "<a href=\"#{href}\">#{text}</a>"
            end
          else
            result += if child.text?
              child.text
            else
              child.to_html
            end
          end
        end
        result.strip
      end
    end
  end
end
