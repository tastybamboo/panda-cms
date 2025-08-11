# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class SettingsController < ::Panda::CMS::Admin::BaseController
        before_action :set_initial_breadcrumb, only: %i[index show]

        def index
        end

        def show
        end

        private

        def set_initial_breadcrumb
          add_breadcrumb "Settings", admin_cms_settings_path
        end
      end
    end
  end
end
