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
          end
        end
      end
    end
  end
end
