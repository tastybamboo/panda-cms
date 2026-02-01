# frozen_string_literal: true

module Panda
  module CMS
    module FormsHelper
      # Generates a hidden timing field for spam protection
      # This should be included in all forms that submit to Panda::CMS::FormSubmissionsController
      #
      # @example In your form
      #   <%= form_with url: form_submissions_path(form.id), method: :post do |f| %>
      #     <%= panda_cms_form_timestamp %>
      #     <%= f.text_field :name %>
      #     <%= f.submit "Submit" %>
      #   <% end %>
      #
      # @return [String] HTML hidden input with current timestamp
      def panda_cms_form_timestamp
        hidden_field_tag "_form_timestamp", Time.current.to_i
      end

      # Generates a complete spam-protected form wrapper
      # Includes timing protection and invisible captcha honeypot
      #
      # @param form [Panda::CMS::Form] The form model
      # @param options [Hash] Additional options for form_with
      # @yield [FormBuilder] The form builder
      #
      # @example
      #   <%= panda_cms_protected_form(form) do |f| %>
      #     <%= f.text_field :name %>
      #     <%= f.email_field :email %>
      #     <%= f.text_area :message %>
      #     <%= f.submit "Send Message" %>
      #   <% end %>
      def panda_cms_protected_form(form, options = {}, &block)
        default_options = {
          url: "/forms/#{form.id}",
          method: :post,
          data: {turbo: false}
        }

        form_with(**default_options.merge(options)) do |f|
          concat panda_cms_form_timestamp
          concat invisible_captcha_field
          yield f
        end
      end

      # Generates the invisible captcha honeypot field
      # This is a hidden field that bots typically fill out but humans don't
      #
      # @return [String] HTML for invisible captcha field
      def invisible_captcha_field
        # invisible_captcha gem automatically adds this, but we can add it manually if needed
        # The field name "spinner" is configured in invisible_captcha initializer
        text_field_tag :spinner, nil, style: "position: absolute; left: -9999px; width: 1px; height: 1px;", tabindex: -1, autocomplete: "off", aria_hidden: true
      end

      # Renders a complete form dynamically from its field definitions
      # Includes spam protection and all configured fields
      #
      # @param form [Panda::CMS::Form] The form model with form_fields
      # @param options [Hash] Additional options
      # @option options [String] :class CSS class for the form wrapper
      # @option options [String] :submit_text Text for the submit button (default: "Submit")
      # @option options [String] :submit_class CSS class for the submit button
      #
      # @example
      #   <%= panda_cms_render_form(Panda::CMS::Form.find_by(name: "Contact")) %>
      #
      # @example With options
      #   <%= panda_cms_render_form(form, class: "max-w-lg", submit_text: "Send Message") %>
      def panda_cms_render_form(form, options = {})
        return unless form&.accepting_submissions?

        wrapper_class = options.delete(:class) || ""
        submit_text = options.delete(:submit_text) || "Submit"
        submit_class = options.delete(:submit_class) || "inline-flex items-center rounded-md bg-gray-900 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2"

        panda_cms_protected_form(form, options.merge(class: wrapper_class)) do |f|
          content = ActiveSupport::SafeBuffer.new

          form.form_fields.active.ordered.each do |field|
            content << render_form_field(field)
          end

          content << content_tag(:div, class: "mt-6") do
            content_tag(:button, submit_text, type: "submit", class: submit_class)
          end

          content
        end
      end

      private

      # Renders a single form field based on its type
      # @param field [Panda::CMS::FormField] The field to render
      # @return [String] HTML for the field
      def render_form_field(field)
        content_tag(:div, class: "mb-4") do
          buffer = ActiveSupport::SafeBuffer.new

          # Label (not for hidden fields)
          unless field.field_type == "hidden"
            buffer << content_tag(:label, for: field.name, class: "block text-sm font-medium text-gray-700 mb-1") do
              field.label + (field.required ? " *" : "")
            end
          end

          # Field input based on type
          buffer << render_field_input(field)

          # Hint text
          if field.hint.present?
            buffer << content_tag(:p, field.hint, class: "mt-1 text-sm text-gray-500")
          end

          buffer
        end
      end

      # Renders the actual input element for a field
      # @param field [Panda::CMS::FormField] The field to render
      # @return [String] HTML for the input element
      def render_field_input(field)
        input_class = "block w-full rounded-md border-gray-300 shadow-sm focus:border-gray-500 focus:ring-gray-500 sm:text-sm"

        case field.field_type
        when "text"
          text_field_tag(field.name, nil,
            placeholder: field.placeholder,
            required: field.required,
            class: input_class)
        when "email"
          email_field_tag(field.name, nil,
            placeholder: field.placeholder,
            required: field.required,
            class: input_class)
        when "phone"
          telephone_field_tag(field.name, nil,
            placeholder: field.placeholder,
            required: field.required,
            class: input_class)
        when "url"
          url_field_tag(field.name, nil,
            placeholder: field.placeholder,
            required: field.required,
            class: input_class)
        when "textarea"
          text_area_tag(field.name, nil,
            placeholder: field.placeholder,
            required: field.required,
            rows: 4,
            class: input_class)
        when "select"
          select_tag(field.name,
            options_for_select(parse_options(field.options_list)),
            include_blank: field.placeholder.presence || "Please select...",
            required: field.required,
            class: input_class)
        when "checkbox"
          render_checkbox_group(field)
        when "radio"
          render_radio_group(field)
        when "file"
          file_field_tag(field.name,
            required: field.required,
            class: "block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded file:border-0 file:text-sm file:font-semibold file:bg-gray-100 file:text-gray-700 hover:file:bg-gray-200")
        when "signature"
          render_signature_pad(field)
        when "hidden"
          hidden_field_tag(field.name, field.placeholder)
        when "date"
          date_field_tag(field.name, nil,
            placeholder: field.placeholder,
            required: field.required,
            class: input_class)
        when "number"
          number_field_tag(field.name, nil,
            placeholder: field.placeholder,
            required: field.required,
            min: field.validation_rules[:min],
            max: field.validation_rules[:max],
            step: field.validation_rules[:step] || 1,
            class: input_class)
        else
          text_field_tag(field.name, nil,
            placeholder: field.placeholder,
            required: field.required,
            class: input_class)
        end
      end

      # Renders a group of checkboxes for multi-select fields
      # @param field [Panda::CMS::FormField] The checkbox field
      # @return [String] HTML for the checkbox group
      def render_checkbox_group(field)
        content_tag(:div, class: "space-y-2") do
          parse_options(field.options_list).map do |option|
            value, label = option.is_a?(Array) ? option : [option, option]
            content_tag(:label, class: "flex items-center") do
              check_box_tag("#{field.name}[]", value, false, class: "rounded border-gray-300 text-gray-600 focus:ring-gray-500") +
                content_tag(:span, label, class: "ml-2 text-sm text-gray-700")
            end
          end.join.html_safe
        end
      end

      # Renders a group of radio buttons for single-select fields
      # @param field [Panda::CMS::FormField] The radio field
      # @return [String] HTML for the radio group
      def render_radio_group(field)
        content_tag(:div, class: "space-y-2") do
          parse_options(field.options_list).map do |option|
            value, label = option.is_a?(Array) ? option : [option, option]
            content_tag(:label, class: "flex items-center") do
              radio_button_tag(field.name, value, false, class: "border-gray-300 text-gray-600 focus:ring-gray-500") +
                content_tag(:span, label, class: "ml-2 text-sm text-gray-700")
            end
          end.join.html_safe
        end
      end

      # Renders a canvas-based signature pad using the signature_pad library
      # @param field [Panda::CMS::FormField] The signature field
      # @return [String] HTML for the signature pad
      def render_signature_pad(field)
        controller_data = {
          controller: "signature-pad",
          signature_pad_required_value: field.required
        }

        content_tag(:div, data: controller_data) do
          buffer = ActiveSupport::SafeBuffer.new

          buffer << content_tag(:canvas, nil,
            data: {signature_pad_target: "canvas"},
            class: "w-full border border-gray-300 rounded-md cursor-crosshair",
            style: "height: 200px; touch-action: none;",
            role: "application",
            aria: {label: "#{field.label} drawing area"})

          buffer << hidden_field_tag(field.name, nil,
            data: {signature_pad_target: "hiddenField"})

          buffer << content_tag(:button, "Clear",
            type: "button",
            data: {action: "click->signature-pad#clear"},
            class: "mt-2 text-sm text-gray-600 hover:text-gray-800 underline")

          buffer
        end
      end

      # Parses options which can be strings or value|label pairs
      # @param options [Array<String>] Array of option strings
      # @return [Array<Array>] Array of [value, label] pairs
      def parse_options(options)
        options.map do |option|
          if option.include?("|")
            parts = option.split("|", 2)
            [parts[0].strip, parts[1].strip]
          else
            [option, option]
          end
        end
      end
    end
  end
end
