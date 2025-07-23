# frozen_string_literal: true

module Panda
  module CMS
    module ThemeHelper
      # TODO: Move these into one method?
      def h1(text, icon: "", additional_styles: "")
        render HeadingComponent.new(text: text, level: 1, icon: icon, additional_styles: additional_styles)
      end

      def h2(text, icon: "", additional_styles: "")
        render HeadingComponent.new(text: text, level: 2, icon: icon, additional_styles: additional_styles)
      end

      def h3(text, icon: "", additional_styles: "")
        render HeadingComponent.new(text: text, level: 3, icon: icon, additional_styles: additional_styles)
      end
    end
  end
end
