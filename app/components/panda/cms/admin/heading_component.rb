# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class HeadingComponent < ViewComponent::Base
        renders_many :buttons, Panda::CMS::Admin::ButtonComponent

        attr_reader :text, :level, :icon, :additional_styles

        def initialize(text:, level: 2, icon: "", additional_styles: "")
          @text = text
          @level = level
          @icon = icon
          @additional_styles = additional_styles
          @additional_styles = @additional_styles.split(" ") if @additional_styles.is_a?(String)
        end

        def call
          output = ""
          output += content_tag(:div, @text, class: "grow")

          if buttons?
            output += content_tag(:span, class: "actions flex gap-x-2 -mt-1") do
              safe_join(buttons, "")
            end
          end

          output = output.html_safe
          base_heading_styles = "flex pt-1 text-black mb-5 -mt-1"

          case level
          when 1
            content_tag(:h1, output, class: [base_heading_styles, "text-2xl font-medium", @additional_styles])
          when 2
            content_tag(:h2, output, class: [base_heading_styles, "text-xl font-medium", @additional_styles])
          when 3
            content_tag(:h3, output, class: [base_heading_styles, "text-xl", "font-light", @additional_styles])
          when :panel
            content_tag(:h3, output, class: ["text-base font-medium p-4 text-white"])
          end
        end
      end
    end
  end
end
