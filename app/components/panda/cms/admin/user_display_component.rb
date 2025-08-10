# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class UserDisplayComponent < ViewComponent::Base
        attr_accessor :user_id, :user, :metadata

        def initialize(user_id: nil, user: nil, metadata: "")
          @user = if user.nil? && user_id.present? && Panda::Core::User.find(user_id)
            Panda::Core::User.find(user_id)
          else
            user
          end

          @metadata = metadata
        end
      end
    end
  end
end
