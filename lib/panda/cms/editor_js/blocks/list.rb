# frozen_string_literal: true

module Panda
  module CMS
    module EditorJs
      module Blocks
        class List < Base
          def render
            list_type = (data["style"] == "ordered") ? "ol" : "ul"
            html_safe(
              "<#{list_type}>" \
              "#{render_items(data["items"])}" \
              "</#{list_type}>"
            )
          end

          private

          def render_items(items)
            items.map do |item|
              content = item.is_a?(Hash) ? item["content"] : item
              nested = (item.is_a?(Hash) && item["items"].present?) ? render_nested(item["items"]) : ""
              "<li>#{sanitize(content)}#{nested}</li>"
            end.join
          end

          def render_nested(items)
            self.class.new({"items" => items, "style" => data["style"]}).render
          end
        end
      end
    end
  end
end
