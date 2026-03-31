# frozen_string_literal: true

module Panda
  module CMS
    class Engine < ::Rails::Engine
      # Helper configuration
      module HelperConfig
        extend ActiveSupport::Concern

        included do
          # Make helpers available to ApplicationController
          config.to_prepare do
            ApplicationController.helper(::ApplicationHelper)
            ApplicationController.helper(Panda::CMS::AssetHelper)
            ApplicationController.helper(Panda::CMS::AnalyticsHelper)
            ApplicationController.helper(Panda::CMS::SocialSharingHelper)

            # Make host app helpers available in engine mailers so the host
            # app's mailer layout can reference its own helpers (e.g. email_logo_url)
            Panda::CMS::ApplicationMailer.helper(Rails.application.helpers)
          end
        end
      end
    end
  end
end
