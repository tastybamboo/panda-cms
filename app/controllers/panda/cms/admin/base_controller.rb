# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      # Base controller for all CMS admin controllers
      # Inherits from Panda::Core::Admin::BaseController for authentication and base admin functionality
      class BaseController < ::Panda::Core::Admin::BaseController
        layout "panda/cms/application"

        # Override set_current_request_details to also set CMS-specific attributes
        def set_current_request_details
          super # Call Core's implementation first

          # Set CMS current attributes (inherits from Core so has access to all Core attributes)
          Panda::CMS::Current.request_id = request.uuid
          Panda::CMS::Current.user_agent = request.user_agent
          Panda::CMS::Current.ip_address = request.ip
          Panda::CMS::Current.root = request.base_url
          Panda::CMS::Current.user = Panda::Core::Current.user
          Panda::CMS::Current.page = nil

          Panda::CMS.config.url ||= Panda::Core::Current.root
        end

        # Include CMS helpers so views have access to panda_cms_form_with, etc.
        helper Panda::CMS::ApplicationHelper

        # Include the helper methods in the controller as well
        include Panda::CMS::ApplicationHelper
      end
    end
  end
end
