# frozen_string_literal: true

module Panda
  module CMS
    module EditorJs
      module Blocks
        class Alert < Base
          def render
            message = sanitize(data["message"])
            type = data["type"] || "primary"

            html_safe(
              "<div class=\"#{alert_classes(type)} p-4 mb-4 rounded-lg\">" \
                "#{message}" \
              "</div>"
            )
          end

          private

          def alert_classes(type)
            case type
            when "primary" then "bg-blue-100 text-blue-800"
            when "secondary" then "bg-gray-100 text-gray-800"
            when "success" then "bg-green-100 text-green-800"
            when "danger" then "bg-red-100 text-red-800"
            when "warning" then "bg-yellow-100 text-yellow-800"
            when "info" then "bg-indigo-100 text-indigo-800"
            else "bg-blue-100 text-blue-800"
            end
          end
        end
      end
    end
  end
end
