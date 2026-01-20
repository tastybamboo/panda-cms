# frozen_string_literal: true

module Panda
  module CMS
    class Engine < ::Rails::Engine
      # ViewComponent configuration for panda-cms
      module ViewComponentConfig
        extend ActiveSupport::Concern

        included do
          # Load ViewComponent base component after Rails application is initialized
          initializer "panda_cms.view_component_base", after: :load_config_initializers do
            require "view_component"

            # Load the base component
            require root.join("app/components/panda/cms/base")
          end
        end
      end
    end
  end
end
