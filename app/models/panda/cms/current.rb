# frozen_string_literal: true

module Panda
  module CMS
    class Current < ActiveSupport::CurrentAttributes
      attribute :root, :page
      attribute :user
      attribute :request_id, :user_agent, :ip_address

      # resets { Time.zone = nil }

      # def user=(user)
      # super
      # self.account = user.account
      # Time.zone = user.time_zone
      # end
    end
  end
end
