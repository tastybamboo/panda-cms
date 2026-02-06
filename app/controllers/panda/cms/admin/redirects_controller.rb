# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class RedirectsController < ::Panda::CMS::Admin::BaseController
        before_action :set_initial_breadcrumb
        before_action :set_redirect, only: %i[edit update destroy]

        # Lists all redirects
        # @type GET
        # @return ActiveRecord::Collection A list of all redirects
        def index
          redirects = Panda::CMS::Redirect.order(:origin_path)
          render :index, locals: {redirects: redirects}
        end

        # New redirect
        # @type GET
        def new
          redirect_record = Panda::CMS::Redirect.new(status_code: 301, visits: 0)
          add_breadcrumb "New Redirect", new_admin_cms_redirect_path
          render :new, locals: {redirect_record: redirect_record}
        end

        # Create redirect
        # @type POST
        def create
          redirect_record = Panda::CMS::Redirect.new(redirect_params)
          redirect_record.visits ||= 0

          if redirect_record.save
            redirect_to edit_admin_cms_redirect_path(redirect_record), notice: "Redirect was successfully created."
          else
            add_breadcrumb "New Redirect", new_admin_cms_redirect_path
            render :new, locals: {redirect_record: redirect_record}, status: :unprocessable_entity
          end
        end

        # Edit redirect
        # @type GET
        def edit
          add_breadcrumb @redirect_record.origin_path, edit_admin_cms_redirect_path(@redirect_record)
          render :edit, locals: {redirect_record: @redirect_record}
        end

        # Update redirect
        # @type PATCH/PUT
        def update
          if @redirect_record.update(redirect_params)
            redirect_to edit_admin_cms_redirect_path(@redirect_record), notice: "Redirect was successfully updated.", status: :see_other
          else
            add_breadcrumb @redirect_record.origin_path, edit_admin_cms_redirect_path(@redirect_record)
            render :edit, locals: {redirect_record: @redirect_record}, status: :unprocessable_entity
          end
        end

        # Delete redirect
        # @type DELETE
        def destroy
          @redirect_record.destroy
          redirect_to admin_cms_redirects_path, notice: "Redirect was successfully deleted.", status: :see_other
        end

        private

        def set_redirect
          @redirect_record = Panda::CMS::Redirect.find(params[:id])
        end

        def set_initial_breadcrumb
          add_breadcrumb "Redirects", admin_cms_redirects_path
        end

        # Only allow a list of trusted parameters through
        # @type private
        # @return ActionController::StrongParameters
        def redirect_params
          params.require(:redirect).permit(:origin_path, :destination_path, :status_code)
        end
      end
    end
  end
end
