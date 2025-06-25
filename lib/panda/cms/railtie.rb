# frozen_string_literal: true

module Panda
  module CMS
    class Railtie < Rails::Railtie
      config.before_initialize do
        Rails.autoloaders.main.inflector.inflect(
          "cms" => "CMS"
        )
      end
    end
  end
end
