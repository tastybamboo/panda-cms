# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class StatisticsComponent < Panda::Core::Base
        prop :metric, String
        prop :value, _Nilable(_Union(Integer, String)), default: 0

        def view_template
          div(class: "overflow-hidden bg-white rounded-lg shadow") do
            div(class: "p-5") do
              div(class: "flex items-center") do
                div(class: "flex-1 w-0") do
                  dl do
                    dt(class: "text-sm font-medium text-gray-500 truncate") { @metric }
                    dd do
                      div(class: "text-lg font-medium text-gray-900") { @value.to_s }
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
