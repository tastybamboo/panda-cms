# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class FormSubmissionsController < ::Panda::CMS::Admin::BaseController
        before_action :set_form
        before_action :set_submission, only: [:show]

        def show
          add_breadcrumb "Forms", admin_cms_forms_path
          add_breadcrumb @form.name, admin_cms_form_path(@form)
          add_breadcrumb "Submission"

          fields = if @form.form_fields.any?
            @form.form_fields.active.ordered.map { |f| [f.name, f.label, f.field_type] }
          elsif @submission.data.present?
            @submission.data.keys.map { |field| [field, field.titleize, "text"] }
          else
            []
          end

          render :show, locals: {form: @form, submission: @submission, fields: fields}
        end

        private

        def set_form
          @form = Panda::CMS::Form.find(params[:form_id])
        end

        def set_submission
          @submission = @form.form_submissions.find(params[:id])
        end
      end
    end
  end
end
