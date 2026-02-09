# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class LinkMetadataController < ::Panda::CMS::Admin::BaseController
        skip_forgery_protection only: [:create]

        def create
          url = params[:url].to_s.strip
          if url.blank?
            return render json: {success: 0, meta: {}}
          end

          meta = Panda::CMS::LinkMetadataService.call(url)
          render json: {success: 1, meta: meta}
        rescue => e
          Rails.logger.warn("[Panda CMS] Link metadata fetch failed for #{url}: #{e.message}")
          render json: {success: 0, meta: {}}
        end
      end
    end
  end
end
