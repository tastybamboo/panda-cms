# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class SessionsController < ApplicationController
        layout "panda/cms/public"

        def new
          @providers = Panda::CMS.config.authentication.select { |_, v| v[:enabled] && !v[:hidden] }.keys
        end

        def create
          user_info = request.env.dig("omniauth.auth", "info")
          provider = params[:provider].to_sym

          if ENV["CI"]
            Rails.logger.info "[AUTH DEBUG] Provider: #{provider}"
            Rails.logger.info "[AUTH DEBUG] Provider enabled: #{Panda::CMS.config.authentication.dig(provider, :enabled)}"
            Rails.logger.info "[AUTH DEBUG] User info: #{user_info.inspect}"
            Rails.logger.info "[AUTH DEBUG] Full omniauth hash: #{request.env["omniauth.auth"].inspect}"
          end

          unless Panda::CMS.config.authentication.dig(provider, :enabled)
            Rails.logger.error "Authentication provider '#{provider}' is not enabled"
            redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
            return
          end

          user = Panda::CMS::User.find_by(email: user_info["email"])

          if ENV["CI"]
            Rails.logger.info "[AUTH DEBUG] Found user: #{user.inspect}"
          end

          if !user && Panda::CMS.config.authentication.dig(provider, :create_account_on_first_login)
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
            Rails.logger.error "User does not exist: #{user_info["email"]}"
            redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
            return
          end

          unless user.admin?
            # User can't be found with this email address or can't login
            Rails.logger.error "User ID #{user.id} attempted admin login, is not admin."
            redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
            return
          end

          session[:user_id] = user.id
          Panda::CMS::Current.user = user

          redirect_path = request.env["omniauth.origin"] || admin_dashboard_path
          
          if ENV["CI"]
            Rails.logger.info "[AUTH DEBUG] Session user_id set to: #{session[:user_id]}"
            Rails.logger.info "[AUTH DEBUG] Redirecting to: #{redirect_path}"
          end
          
          redirect_to redirect_path, flash: {success: t("panda.cms.admin.sessions.create.success")}
        rescue ::OmniAuth::Strategies::OAuth2::CallbackError => e
          Rails.logger.error "OAuth2 login callback error: #{e.message}"
          redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
        rescue ::OAuth2::Error => e
          Rails.logger.error "OAuth2 login error: #{e.message}"
          redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
        rescue => e
          Rails.logger.error "Unknown login error: #{e.message}"
          Rails.logger.error "Unknown login error backtrace: #{e.backtrace.join("\n")}" if ENV["CI"]
          redirect_to admin_login_path, flash: {error: t("panda.cms.admin.sessions.create.error")}
        end

        def failure
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
