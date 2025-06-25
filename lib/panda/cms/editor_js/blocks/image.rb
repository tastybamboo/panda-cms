# frozen_string_literal: true

module Panda
  module CMS
    module EditorJs
      module Blocks
        class Image < Base
          def render
            url = data["url"]
            caption = sanitize(data["caption"])
            with_border = data["withBorder"]
            with_background = data["withBackground"]
            stretched = data["stretched"]

            css_classes = ["prose"]
            css_classes << "border" if with_border
            css_classes << "bg-gray-100" if with_background
            css_classes << "w-full" if stretched

            html_safe(<<~HTML)
              <figure class="#{css_classes.join(" ")}">
                <img src="#{url}" alt="#{caption}" />
                #{caption_element(caption)}
              </figure>
            HTML
          end

          private

          def caption_element(caption)
            return "" if caption.blank?

            "<figcaption>#{caption}</figcaption>"
          end
        end
      end
    end
  end
end
