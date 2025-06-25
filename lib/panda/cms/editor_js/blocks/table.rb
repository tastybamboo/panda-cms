# frozen_string_literal: true

module Panda
  module CMS
    module EditorJs
      module Blocks
        class Table < Base
          def render
            content = data["content"]
            with_headings = data["withHeadings"]

            html_safe(<<~HTML)
              <div class="overflow-x-auto">
                <table class="min-w-full">
                  #{render_rows(content, with_headings)}
                </table>
              </div>
            HTML
          end

          private

          def render_rows(content, with_headings)
            rows = []
            index = 0

            while index < content.length
              rows << if index.zero? && with_headings
                render_header_row(content[index])
              else
                render_data_row(content[index])
              end
              index += 1
            end

            rows.join("\n")
          end

          def render_header_row(row)
            cells = row.map { |cell| "<th>#{sanitize(cell)}</th>" }
            "<tr>#{cells.join}</tr>"
          end

          def render_data_row(row)
            cells = row.map { |cell| "<td>#{sanitize(cell)}</td>" }
            "<tr>#{cells.join}</tr>"
          end
        end
      end
    end
  end
end
