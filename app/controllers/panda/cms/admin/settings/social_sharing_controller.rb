# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      module Settings
        class SocialSharingController < ::Panda::CMS::Admin::BaseController
          before_action :set_initial_breadcrumb

          def index
            @networks = Panda::CMS::SocialSharingNetwork.ordered
            @helper_detected = helper_detected?
          end

          def update
            network = Panda::CMS::SocialSharingNetwork.find(params[:id])
            network.update!(enabled: !network.enabled)

            status = network.enabled? ? "enabled" : "disabled"
            redirect_to admin_cms_settings_social_sharing_path,
              flash: {success: "#{network.display_name} sharing #{status}."}
          end

          private

          def set_initial_breadcrumb
            add_breadcrumb "Settings", admin_cms_settings_path
            add_breadcrumb "Social Sharing", admin_cms_settings_social_sharing_path
          end

          def helper_detected?
            view_paths = Rails.root.join("app", "views").to_s
            Dir.glob("#{view_paths}/**/*.erb").any? { |f| File.read(f).include?("panda_social_sharing") }
          rescue
            false
          end
        end
      end
    end
  end
end
