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

          blob = find_existing_blob(file) || ActiveStorage::Blob.create_and_upload!(
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

        def destroy
          blob = ActiveStorage::Blob.find(params[:id])
          blob.purge
          redirect_to admin_cms_files_path, notice: "File was successfully deleted.", status: :see_other
        end

        private

        def find_existing_blob(file)
          checksum = Digest::MD5.file(file.tempfile.path).base64digest
          ActiveStorage::Blob.find_by(checksum: checksum, byte_size: file.size)
        end
      end
    end
  end
end
