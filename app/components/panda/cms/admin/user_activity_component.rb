# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class UserActivityComponent < ViewComponent::Base
        attr_accessor :model, :time, :user

        # @param model [ActiveRecord::Base] Model instance to which the user activity is related
        # @param at [ActiveSupport::TimeWithZone] Time of the activity
        # @param user [Panda::CMS::User] User who performed the activity
        def initialize(model: nil, at: nil, user: nil)
          @model = model
          @user = user if user.is_a?(::Panda::CMS::User)
          @time = at if at.is_a?(::ActiveSupport::TimeWithZone)
        end
      end
    end
  end
end
