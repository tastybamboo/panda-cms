# frozen_string_literal: true

require "groupdate"

module Panda
  module CMS
    module Admin
      class DashboardController < ::Panda::Core::Admin::DashboardController
        before_action :set_initial_breadcrumb, only: %i[show]

        # Override the panda-core dashboard with CMS-specific dashboard
        def show
          # Render the CMS dashboard view
          render "panda/cms/admin/dashboard/show"
        end

        private

        def set_initial_breadcrumb
          add_breadcrumb "Dashboard", admin_cms_dashboard_path
        end
      end
    end
  end
end
