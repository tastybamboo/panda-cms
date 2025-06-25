# frozen_string_literal: true

module Generators
  module Panda
    module CMS
      class InstallGenerator < ::Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        namespace "panda:cms:install"
        desc "Adds the basic configuration for Panda CMS to your Rails app."

        def create_initializer_file
          # Add the initializer
          initializer_path = "config/initializers/panda/cms.rb"
          unless File.exist?("#{::Rails.root}/#{initializer_path}")
            FileUtils.cp "#{::Panda::CMS::Engine.root}/#{initializer_path}", "#{::Rails.root}/#{initializer_path}"
          end

          # Add the seed loader to the seeds.rb file
          unless File.read("#{::Rails.root}/db/seeds.rb")&.include?("Panda::CMS::Engine.load_seed")
            existing_seeds = File.read("#{::Rails.root}/db/seeds.rb")
            IO.write("#{::Rails.root}/db/seeds.rb", "Panda::CMS::Engine.load_seed\n\n#{existing_seeds}")
          end

          `rails db:migrate`
          `rails db:seed`
        end
      end
    end
  end
end
