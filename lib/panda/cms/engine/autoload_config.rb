# frozen_string_literal: true

module Panda
  module CMS
    class Engine < ::Rails::Engine
      # Autoload paths configuration
      module AutoloadConfig
        extend ActiveSupport::Concern

        included do
          # Add services directory to autoload paths
          config.autoload_paths += %W[
            #{root}/app/services
          ]
        end
      end
    end
  end
end
