# frozen_string_literal: true

module Panda
  module CMS
    module EditorJs
      module Blocks
        class Quote < Base
          def render
            text = data["text"]
            caption = data["caption"]
            alignment = data["alignment"] || "left"

            # Build the HTML structure
            html = "<figure class=\"text-#{alignment}\">" \
              "<blockquote>#{wrap_text_in_p(text)}</blockquote>" \
              "#{caption_element(caption)}" \
              "</figure>"

            # Return raw HTML - validation will be handled by the main renderer if enabled
            html_safe(html)
          end

          private

          def wrap_text_in_p(text)
            # Only wrap in <p> if it's not already wrapped
            text = sanitize(text)
            if text.start_with?("<p>") && text.end_with?("</p>")
              text
            else
              "<p>#{text}</p>"
            end
          end

          def caption_element(caption)
            return "" if caption.blank?

            "<figcaption>#{sanitize(caption)}</figcaption>"
          end
        end
      end
    end
  end
end
