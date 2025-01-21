module Panda
  module CMS
    class PagesController < ApplicationController
      include ActionView::Helpers::TagHelper

      before_action :check_login_required, only: [:root, :show]
      before_action :handle_redirects, only: [:root, :show]
      after_action :record_visit, only: [:root, :show], unless: :ignore_visit?

      def root
        params[:path] = ""
        show
      end

      def show
        page = if @overrides&.dig(:page_path_match)
          Panda::CMS::Page.find_by(path: @overrides.dig(:page_path_match))
        else
          Panda::CMS::Page.find_by(path: "/" + params[:path].to_s)
        end

        Panda::CMS::Current.page = page || Panda::CMS::Page.find_by(path: "/404")
        if @overrides
          Panda::CMS::Current.page.title = @overrides&.dig(:title) || page.title
        end

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
        current_path = "/" + params[:path].to_s
        redirect = Panda::CMS::Redirect.find_by(origin_path: current_path)

        if redirect
          redirect.increment!(:visits)

          # Check if the destination is also a redirect
          next_redirect = Panda::CMS::Redirect.find_by(origin_path: redirect.destination_path)
          if next_redirect
            next_redirect.increment!(:visits)
            redirect_to next_redirect.destination_path, status: redirect.status_code and return
          end

          redirect_to redirect.destination_path, status: redirect.status_code and return
        end
      end

      def check_login_required
        if Panda::CMS.config.require_login_to_view && !user_signed_in?
          redirect_to panda_cms_maintenance_path and return
        end
      end

      def ignore_visit?
        # Ignore visits from bots (TODO: make this configurable)
        return true if /bot/i.match?(request.user_agent)
        # Ignore visits from Honeybadger
        return true if request.headers.to_h.key? "Honeybadger-Token"

        false
      end

      def record_visit
        RecordVisitJob.perform_later(
          path: request.path,
          user_id: Current.user&.id,
          redirect_id: @redirect&.id,
          panda_cms_page_id: Current.page&.id,
          user_agent: request.user_agent,
          ip_address: request.remote_ip,
          referer: request.referer,
          utm_source: params[:utm_source],
          utm_medium: params[:utm_medium],
          utm_campaign: params[:utm_campaign],
          utm_term: params[:utm_term],
          utm_content: params[:utm_content]
        )
      end

      def create_redirect_if_path_changed
        if path_changed? && path_was.present?
          Panda::CMS::Redirect.create!(
            origin_path: path_was,
            destination_path: path,
            status_code: 301
          )
        end
      end
    end
  end
end
