# frozen_string_literal: true

module Panda
  module CMS
    class PagesController < ApplicationController
      include ActionView::Helpers::TagHelper

      before_action :check_login_required, only: %i[root show]
      before_action :handle_redirects, only: %i[root show]
      after_action :record_visit, only: %i[root show], unless: :ignore_visit?

      def root
        params[:path] = ""
        show
      end

      def show
        page = if @overrides&.dig(:page_path_match)
          Panda::CMS::Page.includes(:template).find_by(path: @overrides[:page_path_match])
        else
          Panda::CMS::Page.includes(:template).find_by(path: "/#{params[:path]}")
        end

        Panda::CMS::Current.page = page || Panda::CMS::Page.find_by(path: "/404")
        Panda::CMS::Current.page.title = @overrides&.dig(:title) || page.title if @overrides

        layout = page&.template&.file_path

        if page.nil? || page.status == "archived" || layout.nil?
          # This works for now, but we may want to override in future (e.g. custom 404s)
          render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found and return
        end

        template_vars = {
          page: page,
          title: Panda::CMS::Current.page&.title || Panda::CMS.config.title
        }

        render inline: "", assigns: template_vars, status: :ok, layout: layout
      end

      private

      def handle_redirects
        current_path = "/#{params[:path]}"
        redirect = Panda::CMS::Redirect.find_by(origin_path: current_path)

        return unless redirect

        redirect.increment!(:visits)

        # Check if the destination is also a redirect
        next_redirect = Panda::CMS::Redirect.find_by(origin_path: redirect.destination_path)
        if next_redirect
          next_redirect.increment!(:visits)
          redirect_to next_redirect.destination_path, status: redirect.status_code and return
        end

        redirect_to redirect.destination_path, status: redirect.status_code and return
      end

      def check_login_required
        return unless Panda::CMS.config.require_login_to_view && !user_signed_in?

        redirect_to panda_cms_maintenance_path and return
      end

      def ignore_visit?
        # Ignore visits from bots (TODO: make this configurable)
        return true if /bot/i.match?(request.user_agent)
        # Ignore visits from Honeybadger
        if request.headers.to_h.key?("Honeybadger-Token") || request.user_agent == "Honeybadger Uptime Check"
          return true
        end
        # Ignore visits where we're asking for PHP files
        return true if request.path.ends_with?(".php")

        # Otherwise, record the visit
        false
      end

      def record_visit
        RecordVisitJob.perform_later(
          path: request.path,
          user_id: Panda::Core::Current.user&.id,
          redirect_id: @redirect&.id,
          page_id: Panda::CMS::Current.page&.id,
          user_agent: request.user_agent,
          ip_address: request.remote_ip,
          referer: request.referer, # TODO: Fix the naming of this column
          params: request.parameters
        )
      end

      def create_redirect_if_path_changed
        return unless path_changed? && path_was.present?

        Panda::CMS::Redirect.create!(
          origin_path: path_was,
          destination_path: path,
          status_code: 301
        )
      end
    end
  end
end
