# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class SessionsController < ApplicationController
        layout "panda/cms/public"

        def new
          puts "[DEBUG] Sessions#new - Available providers: #{Panda::CMS.config.authentication.keys}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
          @providers = Panda::CMS.config.authentication.select { |_, v| v[:enabled] && !v[:hidden] }.keys
          puts "[DEBUG] Sessions#new - Enabled providers: #{@providers}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
        end

        def create
          puts "[DEBUG] Sessions#create started" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
          puts "[DEBUG] Request env omniauth.auth: #{request.env['omniauth.auth']&.inspect}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

          user_info = request.env.dig("omniauth.auth", "info")
          provider = params[:provider].to_sym

          puts "[DEBUG] Provider: #{provider}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
          puts "[DEBUG] User info: #{user_info}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

          unless Panda::CMS.config.authentication.dig(provider, :enabled)
            puts "[DEBUG] Provider not enabled: #{provider}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
            Rails.logger.error "Authentication provider '#{provider}' is not enabled"
            redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
            return
          end

          user = Panda::CMS::User.find_by(email: user_info["email"])
          puts "[DEBUG] User lookup for email '#{user_info["email"]}': #{user ? "found (ID: #{user.id})" : "not found"}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

          if !user && Panda::CMS.config.authentication.dig(provider, :create_account_on_first_login)
            puts "[DEBUG] User not found, attempting to create account" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
            create_as_admin = Panda::CMS.config.authentication.dig(provider, :create_as_admin)

            # Always create the first user as admin, regardless of what our settings look like
            # else we can't ever really login. :)
            create_as_admin = true if !create_as_admin && Panda::CMS::User.count.zero?

            if user_info["first_name"] && user_info["last_name"]
              firstname = user_info["first_name"]
              lastname = user_info["last_name"]
            elsif user_info["name"]
              firstname, lastname = user_info["name"].split(" ", 2)
            end

            user = User.find_or_create_by(
              email: user_info["email"]
            ) do |u|
              u.firstname = firstname
              u.lastname = lastname
              u.admin = create_as_admin
              u.image_url = user_info["image"]
            end
          end

          if user.nil?
            # User can't be found with this email address
            puts "[DEBUG] User still nil after lookup/creation" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
            Rails.logger.error "User does not exist: #{user_info["email"]}"
            redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
            return
          end

          unless user.admin?
            # User can't be found with this email address or can't login
            puts "[DEBUG] User found but not admin: #{user.email} (admin: #{user.admin?})" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
            Rails.logger.error "User ID #{user.id} attempted admin login, is not admin." if user && !user.admin
            redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
            return
          end

          puts "[DEBUG] Authentication successful for user: #{user.email}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
          session[:user_id] = user.id
          Panda::CMS::Current.user = user
          puts "[DEBUG] Session user_id set to: #{session[:user_id]}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
          puts "[DEBUG] Current.user set to: #{Panda::CMS::Current.user&.email}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

          redirect_path = request.env["omniauth.origin"] || admin_dashboard_path
          puts "[DEBUG] Redirecting to: #{redirect_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
          redirect_to redirect_path, flash: {success: t("panda.cms.admin.sessions.create.success")}
        rescue ::OmniAuth::Strategies::OAuth2::CallbackError => e
          puts "[DEBUG] OAuth2 callback error: #{e.message}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
          Rails.logger.error "OAuth2 login callback error: #{e.message}"
          redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
        rescue ::OAuth2::Error => e
          puts "[DEBUG] OAuth2 error: #{e.message}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
          Rails.logger.error "OAuth2 login error: #{e.message}"
          redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
        rescue => e
          puts "[DEBUG] Unknown login error: #{e.class} - #{e.message}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
          puts "[DEBUG] Backtrace: #{e.backtrace.first(5)}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
          Rails.logger.error "Unknown login error: #{e.message}"
          redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
        end

        def failure
          puts "[DEBUG] Login failure: #{params[:message]} from #{params[:origin]} using #{params[:strategy]}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
          Rails.logger.error "Login failure: #{params[:message]} from #{params[:origin]} using #{params[:strategy]}"
          redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
        end

        def destroy
          Panda::CMS::Current.user = nil
          session[:user_id] = nil
          redirect_to admin_login_path, flash: {success: t("panda.cms.admin.sessions.destroy.success")}
        end
      end
    end
  end
end
