# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class PopularPagesComponent < Panda::Core::Base
        def initialize(popular_pages:, period_name: "All Time")
          @popular_pages = popular_pages
          @period_name = period_name
        end

        def view_template
          render Panda::Core::Admin::PanelComponent.new do |panel|
            panel.heading(text: "Popular Pages (#{@period_name})", level: :panel)

            panel.body do
              if @popular_pages.any?
                div(class: "overflow-y-auto max-h-96") do
                  table(class: "min-w-full divide-y divide-gray-300") do
                    thead(class: "sticky top-0 bg-white z-10") do
                      tr do
                        th(class: "py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0") { "Page" }
                        th(class: "px-3 py-3.5 text-left text-sm font-semibold text-gray-900") { "Path" }
                        th(class: "px-3 py-3.5 text-right text-sm font-semibold text-gray-900") { "Views" }
                      end
                    end
                    tbody(class: "divide-y divide-gray-200") do
                      index = 0
                      @popular_pages.each do |page_data|
                        tr(class: index.even? ? "bg-indigo-50" : "bg-white") do
                          td(class: "whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0") do
                            a(
                              href: helpers.admin_cms_page_path(page_data.id),
                              class: "text-indigo-600 hover:text-indigo-900"
                            ) { page_data.title }
                          end
                          td(class: "whitespace-nowrap px-3 py-4 text-sm text-gray-500") do
                            a(
                              href: page_data.path,
                              class: "text-gray-600 hover:text-gray-900",
                              target: "_blank"
                            ) { page_data.path }
                          end
                          td(class: "whitespace-nowrap px-3 py-4 text-sm text-gray-500 text-right font-semibold") do
                            page_data.visit_count.to_s
                          end
                        end
                        index += 1
                      end
                    end
                  end
                end
              else
                p(class: "text-sm text-gray-500") { "No page visits recorded yet." }
              end
            end
          end
        end
      end
    end
  end
end
