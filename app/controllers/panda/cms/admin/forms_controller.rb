# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class FormsController < ::Panda::CMS::Admin::BaseController
        before_action :set_initial_breadcrumb, only: %i[index show]

        # Lists all forms
        # @type GET
        # @return ActiveRecord::Collection A list of all forms
        def index
          forms = Panda::CMS::Form.order(:name)
          render :index, locals: {forms: forms}
        end

        def show
          form = Panda::CMS::Form.find(params[:id])

          add_breadcrumb form.name, admin_form_path(form)
          submissions = form.form_submissions.order(created_at: :desc)
          # TODO: Set a whitelist of fields we allow to be submitted for the form, shown in this view
          # and a formatting array of how to display them... eventually?

          fields = if submissions.last
            submissions.last.data.keys.reverse.map { |field| [field, field.titleize] }
          else
            []
          end

          render :show, locals: {form: form, submissions: submissions, fields: fields}
        end

        private

        def set_initial_breadcrumb
          add_breadcrumb "Forms", admin_forms_path
        end

        # Only allow a list of trusted parameters through
        # @type private
        # @return ActionController::StrongParameters
        def form_params
          params.require(:form).permit(:name, :completion_path)
        end
      end
    end
  end
end
