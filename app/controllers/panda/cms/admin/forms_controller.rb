# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class FormsController < ::Panda::CMS::Admin::BaseController
        before_action :set_initial_breadcrumb
        before_action :set_form, only: %i[show edit update destroy]

        # Lists all forms
        # @type GET
        # @return ActiveRecord::Collection A list of all forms
        def index
          forms = Panda::CMS::Form.order(:name)
          render :index, locals: {forms: forms}
        end

        # Shows form submissions
        # @type GET
        def show
          add_breadcrumb @form.name, admin_cms_form_path(@form)
          submissions = @form.form_submissions.order(created_at: :desc)

          # Use form field definitions if available, otherwise infer from submissions
          # Fields are triples: [name, label, field_type]
          fields = if @form.form_fields.any?
            @form.form_fields.active.ordered.map { |f| [f.name, f.label, f.field_type] }
          elsif submissions.any?
            submissions.last.data.keys.reverse.map { |field| [field, field.titleize, "text"] }
          else
            []
          end

          display_fields = fields.first(3)
          render :show, locals: {form: @form, submissions: submissions, fields: fields, display_fields: display_fields}
        end

        # New form
        # @type GET
        def new
          form = Panda::CMS::Form.new
          add_breadcrumb "New Form", new_admin_cms_form_path
          render :new, locals: {form: form}
        end

        # Create form
        # @type POST
        def create
          form = Panda::CMS::Form.new(form_params)

          if form.save
            redirect_to edit_admin_cms_form_path(form), notice: "Form was successfully created."
          else
            add_breadcrumb "New Form", new_admin_cms_form_path
            render :new, locals: {form: form}, status: :unprocessable_entity
          end
        end

        # Edit form
        # @type GET
        def edit
          add_breadcrumb @form.name, admin_cms_form_path(@form)
          add_breadcrumb "Edit", edit_admin_cms_form_path(@form)
          render :edit, locals: {form: @form}
        end

        # Update form
        # @type PATCH/PUT
        def update
          if @form.update(form_params)
            redirect_to edit_admin_cms_form_path(@form), notice: "Form was successfully updated.", status: :see_other
          else
            add_breadcrumb @form.name, admin_cms_form_path(@form)
            add_breadcrumb "Edit", edit_admin_cms_form_path(@form)
            render :edit, locals: {form: @form}, status: :unprocessable_entity
          end
        end

        # Delete form
        # @type DELETE
        def destroy
          @form.destroy
          redirect_to admin_cms_forms_path, notice: "Form was successfully deleted.", status: :see_other
        end

        private

        def set_form
          @form = Panda::CMS::Form.find(params[:id])
        end

        def set_initial_breadcrumb
          add_breadcrumb "Forms", admin_cms_forms_path
        end

        # Only allow a list of trusted parameters through
        # @type private
        # @return ActionController::StrongParameters
        def form_params
          params.require(:form).permit(
            :name, :description, :status, :completion_path,
            :notification_emails, :notification_subject,
            :send_confirmation, :confirmation_subject, :confirmation_body, :confirmation_email_field,
            :success_message,
            form_fields_attributes: [
              :id, :name, :label, :field_type, :placeholder, :hint,
              :required, :position, :active, :options, :validations, :_destroy
            ]
          )
        end
      end
    end
  end
end
