# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class PanelComponent < ViewComponent::Base
        renders_one :heading, lambda { |text:, icon: "", level: :panel, additional_styles: ""|
          Panda::CMS::Admin::HeadingComponent.new(text: text, icon: icon, level: level, additional_styles: additional_styles)
        }
      end
    end
  end
end
