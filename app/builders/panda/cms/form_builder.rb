module Panda
  module CMS
    class FormBuilder < ActionView::Helpers::FormBuilder
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::FormTagHelper

      def label(attribute, text = nil, options = {}, &block)
        super(attribute, text, options.reverse_merge(class: label_styles))
      end

      def text_field(attribute, options = {})
        if options.dig(:data, :prefix)
          content_tag :div, class: container_styles do
            label(attribute) + meta_text(options) +
              content_tag(:div, class: "flex flex-grow") do
                content_tag(:span, class: "inline-flex items-center px-3 text-base border border-r-none rounded-s-md whitespace-nowrap break-keep") { options.dig(:data, :prefix) } +
                  super(attribute, options.reverse_merge(class: input_styles_prefix + " input-prefix rounded-l-none border-l-none"))
              end + error_message(attribute)
          end
        else
          content_tag :div, class: container_styles do
            label(attribute) + meta_text(options) + super(attribute, options.reverse_merge(class: input_styles)) + error_message(attribute)
          end
        end
      end

      def email_field(method, options = {})
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, options.reverse_merge(class: input_styles)) + error_message(method)
        end
      end

      def datetime_field(method, options = {})
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, options.reverse_merge(class: input_styles)) + error_message(method)
        end
      end

      def text_area(method, options = {})
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, options.reverse_merge(class: input_styles)) + error_message(method)
        end
      end

      def password_field(attribute, options = {})
        content_tag :div, class: container_styles do
          label(attribute) + meta_text(options) + super(attribute, options.reverse_merge(class: input_styles)) + error_message(attribute)
        end
      end

      def select(method, choices = nil, options = {}, html_options = {}, &block)
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, choices, options, html_options.reverse_merge(class: select_styles)) + select_svg + error_message(method)
        end
      end

      def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, collection, value_method, text_method, options, html_options.reverse_merge(class: input_styles)) + error_message(method)
        end
      end

      def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
        wrap_field(method, options) do
          super(
            method,
            priority_zones,
            options,
            html_options.reverse_merge(class: select_styles)
          )
        end
      end

      def file_field(method, options = {})
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, options.reverse_merge(class: "file:rounded file:border-0 file:text-sm file:bg-white file:text-gray-500 hover:file:bg-gray-50 bg-white px-2.5 hover:bg-gray-50".concat(input_styles)))
        end
      end

      def button(value = nil, options = {}, &block)
        value ||= submit_default_value
        options = options.dup

        # Handle formmethod specially
        if options[:formmethod] == "delete"
          options[:name] = "_method"
          options[:value] = "delete"
        end

        base_classes = [
          "inline-flex items-center rounded-md",
          "px-3 py-2",
          "text-base font-semibold",
          "shadow-sm"
        ]

        # Only add fa-circle-check for non-block buttons
        base_classes << "fa-circle-check" unless block_given?

        options[:class] = [
          *base_classes,
          options[:class]
        ].compact.join(" ")

        if block_given?
          @template.button_tag(options, &block)
        else
          @template.button_tag(value, options)
        end
      end

      def submit(value = nil, options = {})
        value ||= submit_default_value

        # Use the same style logic as ButtonComponent
        action = object.persisted? ? :save : :create
        button_classes = case action
        when :save, :create
          "text-white bg-active"
        when :save_inactive
          "text-white bg-inactive"
        when :secondary
          "text-dark border-2 border-mid bg-transparent hover:bg-light transition-all"
        else
          "text-dark border-2 border-mid bg-transparent hover:bg-light transition-all"
        end

        # Combine with common button classes
        classes = "inline-flex items-center rounded-md font-medium shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 px-3 py-2 #{button_classes}"

        options[:class] = options[:class] ? "#{options[:class]} #{classes}" : classes

        super
      end

      def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, options.reverse_merge(class: "border-gray-300 ml-2"), checked_value, unchecked_value)
        end
      end

      def date_field(method, options = {})
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, options.reverse_merge(class: input_styles))
        end
      end

      def rich_text_area(method, options = {})
        content_tag :div, class: container_styles do
          label(method) + meta_text(options) + super(method, options.reverse_merge(class: textarea_styles))
        end
      end

      def rich_text_field(method, options = {})
        wrap_field(method, options) do
          if defined?(ActionText)
            # For test environment
            if Rails.env.test?
              # Just render a textarea for testing
              text_area(method, options.reverse_merge(class: textarea_styles))
            else
              rich_text_area(method, options.reverse_merge(class: textarea_styles))
            end
          else
            text_area(method, options.reverse_merge(class: textarea_styles))
          end
        end
      end

      def meta_text(options)
        return unless options[:meta]
        @template.content_tag(:p, options[:meta], class: "block text-black/60 text-sm mb-2")
      end

      private

      def label_styles
        "font-light inline-block mb-1 text-base leading-6"
      end

      def base_input_styles
        "bg-white block w-full rounded-md border border-mid focus:border-mid p-2 text-dark outline-0 focus:outline-0 ring-0 focus:ring-0 focus:ring-mid ring-offset-0 focus:ring-offset-0 shadow-none focus:shadow-none border-mid"
      end

      def input_styles
        base_input_styles
      end

      def input_styles_prefix
        input_styles.concat(" prefix")
      end

      def select_styles
        "col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-1.5 pl-3 pr-8 text-dark text-base outline-0 outline-dark focus:outline focus:-outline-offset-2 focus:outline-dark"
      end

      def select_svg
        @template.content_tag(:svg, class: "pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-gray-400", aria_hidden: true) do
          @template.content_tag(:path, d: "M9.293 12.95l.707.707L15.657 8l-1.414-1.414L10 10.828 5.757 6.586 4.343 8z")
        end
      end

      def button_styles
        "inline-flex items-center rounded-md font-medium shadow-sm focus-visible:outline focus-visible:outline-0 focus-visible:outline-offset-none text-dark border-2 border-mid bg-transparent hover:bg-light transition-all gap-x-1.5 px-3 py-2 text-base gap-x-1.5 px-2.5 py-1.5 mt-2 "
      end

      def container_styles
        "panda-cms-field-container mb-4"
      end

      def textarea_styles
        input_styles.concat(" min-h-32")
      end

      def submit_default_value
        object.persisted? ? "Update #{object.class.name.demodulize}" : "Create #{object.class.name.demodulize}"
      end

      def wrap_field(method, options = {}, &block)
        @template.content_tag(:div, class: "panda-cms-field-container") do
          label(method, class: "font-light inline-block mb-1 text-base leading-6") +
            meta_text(options) +
            @template.content_tag(:div, class: field_wrapper_styles, &block)
        end
      end

      def field_wrapper_styles
        "mt-1"
      end

      def error_message(attribute)
        return unless object.respond_to?(:errors) && object.errors[attribute]&.any?
        content_tag(:p, class: "mt-2 text-sm text-red-600") do
          object.errors[attribute].join(", ")
        end
      end
    end
  end
end
