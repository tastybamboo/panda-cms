# frozen_string_literal: true

module Panda
  module CMS
    class RecordVisitJob < ApplicationJob
      queue_as :default

      def perform(
        path:,
        user_id: nil,
        redirect_id: nil,
        page_id: nil,
        user_agent: nil,
        ip_address: nil,
        referer: nil,
        params: []
      )
        Panda::CMS::Visit.create!(
          url: path,
          user_id: user_id,
          redirect_id: redirect_id,
          page_id: page_id,
          user_agent: user_agent,
          ip_address: ip_address,
          referrer: referer, # TODO: Fix the naming of this column
          params: params,
          visited_at: Time.current
        )
      end
    end
  end
end
