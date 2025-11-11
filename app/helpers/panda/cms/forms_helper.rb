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
    end
  end
end
