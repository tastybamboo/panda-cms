# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class MyProfileController < ApplicationController
        before_action :set_initial_breadcrumb, only: %i[edit update]
        before_action :authenticate_admin_user!

        # Shows the edit form for the current user's profile
        # @type GET
        # @return void
        def edit
          render :edit, locals: {user: current_user}
        end

        # Updates the current user's profile
        # @type PATCH/PUT
        # @return void
        def update
          puts "[DEBUG] MyProfile update - params: #{user_params.inspect}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
          puts "[DEBUG] MyProfile update - current user before: #{current_user.inspect}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

          if current_user.update(user_params)
            puts "[DEBUG] MyProfile update SUCCESS - setting flash message" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
            flash[:success] = "Your profile has been updated successfully."
            puts "[DEBUG] MyProfile update - flash set to: #{flash.inspect}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
            redirect_to edit_admin_my_profile_path
          else
            puts "[DEBUG] MyProfile update FAILED - errors: #{current_user.errors.full_messages}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
            render :edit, locals: {user: current_user}, status: :unprocessable_entity
          end
        end

        private

        def set_initial_breadcrumb
          add_breadcrumb "My Profile", edit_admin_my_profile_path
        end

        # Only allow a list of trusted parameters through
        # @type private
        # @return ActionController::StrongParameters
        def user_params
          params.require(:user).permit(:firstname, :lastname, :email, :current_theme)
        end
      end
    end
  end
end
