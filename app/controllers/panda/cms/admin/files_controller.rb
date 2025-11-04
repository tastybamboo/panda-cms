# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class FilesController < ::Panda::CMS::Admin::BaseController
        def index
          @files = ActiveStorage::Blob.order(created_at: :desc)
          @selected_file = @files.first if @files.any?
        end

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

        private
      end
    end
  end
end
