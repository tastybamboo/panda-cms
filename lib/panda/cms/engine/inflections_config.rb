# frozen_string_literal: true

module Panda
  module CMS
    class Engine < ::Rails::Engine
      # Inflections configuration
      module InflectionsConfig
        extend ActiveSupport::Concern

        included do
          # Load inflections early to ensure proper constant resolution
          initializer "panda_cms.inflections", before: :load_config_initializers do
            ActiveSupport::Inflector.inflections(:en) do |inflect|
              inflect.acronym "CMS"
              inflect.acronym "SEO"
              inflect.acronym "AI"
            end
          end
        end
      end
    end
  end
end
