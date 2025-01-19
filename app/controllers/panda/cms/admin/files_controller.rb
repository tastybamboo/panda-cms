# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class FilesController < ApplicationController
        before_action :authenticate_admin_user!

        def create
          file = params[:image]
          return render json: {success: 0} unless file

          blob = ActiveStorage::Blob.create_and_upload!(
            io: file,
            filename: file.original_filename,
            content_type: file.content_type
          )

          render json: {
            success: true,
            file: {
              url: Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true),
              name: blob.filename.to_s,
              size: blob.byte_size
            }
          }
        end
      end
    end
  end
end
