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
          Panda::CMS::Admin::BaseAnalyticsWidgetComponent.duration_for(param)
        end
      end
    end
  end
end
