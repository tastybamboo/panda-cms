# frozen_string_literal: true

module Panda
  module CMS
    module EditorJs
      module Blocks
        class Header < Base
          def render
            content = sanitize(data["text"])
            level = data["level"] || 2
            html_safe("<h#{level}>#{content}</h#{level}>")
          end
        end
      end
    end
  end
end
