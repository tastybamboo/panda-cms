# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      module PagesHelper
        #
        # Returns pages formatted for select dropdowns with hierarchical indentation
        # Each page is prefixed with dashes based on its depth and shows the path
        #
        # @return [Array<Array<String, Integer>>] Array of [display_text, id] pairs
        # @example
        #   hierarchical_pages_for_select
        #   # => [["Home (/)", 1], ["- About (/about)", 2], ["-- Team (/about/team)", 3]]
        #
        def hierarchical_pages_for_select
          Panda::CMS::Page.order(:lft).map do |page|
            prefix = "- " * page.depth
            display_text = "#{prefix}#{page.title} (#{page.path})"
            [display_text, page.id]
          end
        end
      end
    end
  end
end
