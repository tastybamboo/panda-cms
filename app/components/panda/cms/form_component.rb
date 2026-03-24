# frozen_string_literal: true

module Panda
  module CMS
    # Form component for embedding CMS forms into page templates
    # Admins select which form to display via a dropdown in the page editor
    # @param key [Symbol] The key to use for the form component
    # @param editable [Boolean] If the form is editable or not (defaults to true)
    class FormComponent < Panda::Core::Base
      KIND = "form"

      attr_reader :key, :editable

      def initialize(key:, editable: true, **attrs)
        @key = key
        @editable = editable
        super(**attrs)
      end

      def before_render
        prepare_content
      end

      private

      attr_accessor :block_content_obj, :form_id, :form, :available_forms,
        :block_content_id, :editable_state

      def prepare_content
        @editable_state = component_is_editable?

        block = find_block
        if block.nil?
          report_missing_data("Block not found (kind: #{KIND}, key: #{@key}, template: #{Current.page&.panda_cms_template_id})")
          @editable_state = false
          return
        end

        @block_content_obj = find_block_content(block)
        @form_id = @block_content_obj&.content.to_s.presence
        @block_content_id = @block_content_obj&.id
        @form = Panda::CMS::Form.find_by(id: @form_id) if @form_id
        @available_forms = Panda::CMS::Form.includes(:form_fields).order(:name) if @editable_state

        unless @editable_state
          report_missing_data("BlockContent missing for block #{block.id} on page #{Current.page&.id}") unless @block_content_obj
          report_missing_data("BlockContent has no form ID (content: #{@block_content_obj&.content.inspect})") if @block_content_obj && @form_id.blank?
          report_missing_data("Form not found for ID #{@form_id}") if @form_id.present? && @form.nil?
        end
      end

      def find_block
        Panda::CMS::Block.find_by(
          kind: KIND,
          key: @key,
          panda_cms_template_id: Current.page.panda_cms_template_id
        )
      end

      def find_block_content(block)
        block.block_contents.find_by(panda_cms_page_id: Current.page.id)
      end

      def component_is_editable?
        @editable && is_embedded?
      end

      def is_embedded?
        page_id = Current.page&.id.to_s

        # Check for session-based editing (preferred, more secure)
        editing_page_id = view_context.session[:panda_cms_editing_page_id]
        editing_expires_at = view_context.session[:panda_cms_editing_expires_at]

        session_valid = editing_page_id == page_id &&
          editing_expires_at.present? &&
          Time.parse(editing_expires_at) > Time.current

        # Fall back to URL param for backwards compatibility (will be removed in future)
        embed_id = view_context.params[:embed_id].to_s
        url_param_valid = embed_id.present? && embed_id == page_id

        session_valid || url_param_valid
      end

      def report_missing_data(detail)
        return if @editable_state

        message = "[FormComponent] #{detail} (page: #{Current.page&.path})"
        error = Panda::CMS::MissingBlockDataError.new(message)
        Rails.error.report(error, handled: true, severity: :error, context: {
          component: self.class.name,
          key: @key,
          page_path: Current.page&.path,
          page_id: Current.page&.id,
          template_id: Current.page&.panda_cms_template_id
        })
      end

      public

      # Forms contain CSRF tokens and spam-protection timestamps that are
      # generated per-request, so caching their output would break submissions.
      def should_cache?
        false
      end
    end
  end
end
