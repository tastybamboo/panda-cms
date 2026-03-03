# frozen_string_literal: true

module Panda
  module CMS
    class Engine < ::Rails::Engine
      module SocialSharingConfig
        extend ActiveSupport::Concern

        included do
          initializer "panda.cms.social_sharing" do
            config.after_initialize do
              next unless ActiveRecord::Base.connection.table_exists?("panda_cms_social_sharing_networks")

              Panda::CMS::SocialSharingNetwork.register_all
            rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
              # Skip seeding if database isn't available (e.g. during db:create)
            end
          end
        end
      end
    end
  end
end
