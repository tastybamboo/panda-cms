# frozen_string_literal: true

module Panda
  module CMS
    # @label Menu
    # @tags stable
    # Note: This component requires database records (Menu and MenuItem).
    # Previews will only work if you have test data in your development database.
    class MenuComponentPreview < ViewComponent::Preview
      # Basic menu with default styling
      # @label Default
      def default
        # This is a simplified example - actual usage requires a Menu record
        content_tag :div, class: "p-4 bg-gray-50" do
          "Menu component requires database records. Create a Menu with MenuItems in your development database to see this component in action."
        end
      end

      # Example of menu structure documentation
      # @label Menu Structure Example
      def structure_example
        content_tag :div, class: "p-4 space-y-4" do
          concat content_tag(:h3, "Menu Component Usage", class: "font-bold text-lg")
          concat content_tag(:p, "The MenuComponent renders hierarchical navigation menus from database records.")
          concat content_tag(:pre, class: "bg-gray-100 p-4 rounded text-sm overflow-x-auto") do
            <<~RUBY.html_safe
              # Example usage in a view:
              <%= render Panda::CMS::MenuComponent.new(
                name: "main-navigation",
                current_path: request.path,
                styles: {
                  default: "block py-2 px-4",
                  active: "bg-blue-600 text-white",
                  inactive: "text-gray-700 hover:bg-gray-100"
                }
              ) %>

              # Required database structure:
              # - Menu record with name: "main-navigation"
              # - Associated MenuItem records (nested set structure)
              # - Each MenuItem links to a Page
            RUBY
          end
        end
      end
    end
  end
end
