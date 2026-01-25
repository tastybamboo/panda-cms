# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class PopularPagesComponent < Panda::Core::Base
        attr_reader :popular_pages, :period_name

        def initialize(popular_pages:, period_name: "All Time")
          @popular_pages = popular_pages
          @period_name = period_name
          super()
        end
      end
    end
  end
end
