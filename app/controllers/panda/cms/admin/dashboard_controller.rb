# frozen_string_literal: true

require "groupdate"

module Panda
  module CMS
    module Admin
      class DashboardController < ::Panda::Core::AdminController
        before_action :set_initial_breadcrumb, only: %i[show]

        # GET /admin
        def show
        end

        private

        def set_initial_breadcrumb
          add_breadcrumb "Dashboard", Panda::CMS.route_namespace
        end
      end
    end
  end
end
