# frozen_string_literal: true

module Panda
  module CMS
    # Helpdesk form component for embedding helpdesk ticket forms into CMS page templates.
    # Admins select which helpdesk department to display via a dropdown in the page editor.
    # Requires panda-helpdesk gem to be installed; degrades gracefully if not present.
    # @param key [Symbol] The key to use for the helpdesk form component
    # @param editable [Boolean] If the component is editable or not (defaults to true)
    class HelpdeskFormComponent < Panda::Core::Base
      KIND = "helpdesk_form"

      attr_reader :key, :editable

      def initialize(key:, editable: true, **attrs)
        @key = key
        @editable = editable
        super(**attrs)
      end

      def before_render
        prepare_content
      end

      # Depends on auth state, so must not be cached
      def should_cache?
        false
      end

      private

      attr_accessor :block_content_obj, :department_id, :department, :available_departments,
        :block_content_id, :editable_state, :current_user

      def prepare_content
        @editable_state = component_is_editable?

        unless helpdesk_available?
          @editable_state = false if @editable_state
          return
        end

        block = find_block
        if block.nil?
          @editable_state = false
          return
        end

        @block_content_obj = find_block_content(block)
        @department_id = @block_content_obj&.content.to_s.presence
        @block_content_id = @block_content_obj&.id
        @department = Panda::Helpdesk::Department.find_by(id: @department_id) if @department_id
        @available_departments = Panda::Helpdesk::Department.active.order(:name) if @editable_state
        @current_user = resolve_current_user unless @editable_state
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

        editing_page_id = view_context.session[:panda_cms_editing_page_id]
        editing_expires_at = view_context.session[:panda_cms_editing_expires_at]

        session_valid = editing_page_id == page_id &&
          editing_expires_at.present? &&
          Time.parse(editing_expires_at) > Time.current

        embed_id = view_context.params[:embed_id].to_s
        url_param_valid = embed_id.present? && embed_id == page_id

        session_valid || url_param_valid
      end

      def helpdesk_available?
        defined?(Panda::Helpdesk)
      end

      def resolve_current_user
        return nil unless helpdesk_available?
        Panda::Helpdesk.config.current_user_resolver.call(view_context.session, view_context.request)
      rescue
        nil
      end
    end
  end
end
