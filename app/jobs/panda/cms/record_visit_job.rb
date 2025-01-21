module Panda
  module CMS
    class RecordVisitJob < ApplicationJob
      queue_as :default

      def perform(
        path:,
        user_id: nil,
        redirect_id: nil,
        panda_cms_page_id: nil,
        user_agent: nil,
        ip_address: nil,
        referer: nil,
        utm_source: nil,
        utm_medium: nil,
        utm_campaign: nil,
        utm_term: nil,
        utm_content: nil
      )
        Panda::CMS::Visit.create!(
          path: path,
          user_id: user_id,
          redirect_id: redirect_id,
          panda_cms_page_id: panda_cms_page_id,
          user_agent: user_agent,
          ip_address: ip_address,
          referer: referer,
          utm_source: utm_source,
          utm_medium: utm_medium,
          utm_campaign: utm_campaign,
          utm_term: utm_term,
          utm_content: utm_content
        )
      end
    end
  end
end
