# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class FilesController < ::Panda::CMS::Admin::BaseController
        def index
          @filter = params[:filter] || "recently_viewed"
          @files = load_files_by_filter(@filter)
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

        def load_files_by_filter(filter)
          case filter
          when "recently_added"
            ActiveStorage::Blob.order(created_at: :desc)
          when "recently_viewed"
            # For now, same as recently added - could track views in future
            ActiveStorage::Blob.order(created_at: :desc)
          when "favourited"
            # Placeholder - could add favourites feature later
            ActiveStorage::Blob.none
          else
            ActiveStorage::Blob.order(created_at: :desc)
          end
        end
      end
    end
  end
end
