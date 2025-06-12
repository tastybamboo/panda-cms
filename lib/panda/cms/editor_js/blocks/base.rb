# frozen_string_literal: true

module Panda
  module CMS
    module EditorJs
      module Blocks
        class Base
          include ActionView::Helpers::SanitizeHelper
          include ActionView::Helpers::TagHelper

          attr_reader :data, :options

          def initialize(data, options = {})
            @data = data
            @options = options
          end

          def render
            ""
          end

          protected

          def html_safe(content)
            content.html_safe
          end

          def sanitize(text)
            Rails::Html::SafeListSanitizer.new.sanitize(text, tags: %w[b i u a code])
          end
        end
      end
    end
  end
end
