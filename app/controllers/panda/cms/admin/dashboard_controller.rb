# frozen_string_literal: true

require "groupdate"

module Panda
  module CMS
    module Admin
      class DashboardController < BaseController
        before_action :set_initial_breadcrumb, only: %i[show]

        # CMS-specific dashboard
        def show
          @period = parse_period(params[:period])
          render :show
        end

        private

        def set_initial_breadcrumb
          add_breadcrumb "Dashboard", admin_cms_dashboard_path
        end

        def parse_period(param)
          case param
          when "1h" then 1.hour
          when "24h" then 1.day
          when "7d" then 7.days
          when "90d" then 90.days
          else 30.days
          end
        end
      end
    end
  end
end
