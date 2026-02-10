# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      class FilesController < ::Panda::CMS::Admin::BaseController
        before_action :set_initial_breadcrumb, only: [:index]
        before_action :set_blob, only: [:show, :update, :destroy]

        def index
          # Exclude variant blobs — they are attached to VariantRecord, not user-uploaded
          variant_blob_ids = ActiveStorage::Attachment
            .where(record_type: "ActiveStorage::VariantRecord")
            .select(:blob_id)

          @files = ActiveStorage::Blob
            .where.not(id: variant_blob_ids)
            .includes(:variant_records)
            .order(created_at: :desc)

          @file_categories = Panda::Core::FileCategory.ordered
          @active_category = params[:category]

          # Apply category filter
          if @active_category == "uncategorized"
            categorized_blob_ids = Panda::Core::FileCategorization.select(:blob_id)
            @files = @files.where.not(id: categorized_blob_ids)
          elsif @active_category.present?
            category = Panda::Core::FileCategory.find_by(slug: @active_category)
            if category
              blob_ids = Panda::Core::FileCategorization.where(file_category: category).select(:blob_id)
              @files = @files.where(id: blob_ids)
            end
          end

          # Preload category names for gallery display
          categorizations = Panda::Core::FileCategorization
            .where(blob_id: @files.select(:id))
            .includes(:file_category)
          @blob_categories = categorizations.each_with_object({}) do |cat, hash|
            hash[cat.blob_id] = cat.file_category
          end
        end

        def show
          @file_categories = Panda::Core::FileCategory.ordered

          if request.xhr? || request.headers["Turbo-Frame"].present?
            render partial: "file_details", locals: {file: @blob, file_categories: @file_categories}
          else
            redirect_to admin_cms_files_path
          end
        end

        def create
          # JSON uploads from EditorJS
          if params[:image].present?
            return create_from_editor
          end

          # File uploads from EditorJS AttachesTool
          if params[:file].present?
            return create_file_from_editor
          end

          # HTML form uploads from the file gallery
          file = params.dig(:file_upload, :file)
          category_id = params.dig(:file_upload, :file_category_id)

          if file.blank?
            redirect_to admin_cms_files_path, alert: "Please select a file to upload."
            return
          end

          if category_id.blank?
            redirect_to admin_cms_files_path, alert: "Please select a category."
            return
          end

          unless (category = Panda::Core::FileCategory.find_by(id: category_id))
            redirect_to admin_cms_files_path, alert: "Selected category not found."
            return
          end

          blob = find_existing_blob(file) || ActiveStorage::Blob.create_and_upload!(
            io: file,
            filename: file.original_filename,
            content_type: file.content_type
          )

          stamp_uploader(blob)

          Panda::Core::FileCategorization.find_or_create_by!(file_category: category, blob: blob)

          redirect_to admin_cms_files_path, notice: "File uploaded successfully."
        end

        def update
          blob_params = params.require(:blob).permit(:filename, :description, :file_category_id)

          # Update filename — always re-append the original extension
          new_filename = blob_params[:filename].to_s.strip
          if new_filename.present?
            original_ext = File.extname(@blob.filename.to_s)
            new_filename += original_ext if File.extname(new_filename).blank? && original_ext.present?
            @blob.filename = new_filename
          end

          # Update description in metadata
          metadata = @blob.metadata || {}
          metadata["description"] = blob_params[:description].to_s.strip
          @blob.metadata = metadata

          @blob.save!
          update_file_category(blob_params[:file_category_id])

          @file_categories = Panda::Core::FileCategory.ordered
          locals = {file: @blob, file_categories: @file_categories, notice: "File updated successfully."}
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.update(
                "file-gallery-slideover-content",
                partial: "file_details",
                locals: locals
              )
            end
            format.html do
              redirect_to admin_cms_files_path, notice: "File updated successfully.", status: :see_other
            end
          end
        end

        def destroy
          # Remove variant records and their blobs first (each variant has its own blob)
          @blob.variant_records.includes(image_attachment: :blob).each do |vr|
            vr.image&.purge
            vr.delete
          end

          # Remove remaining FK references before purging the blob
          ActiveStorage::Attachment.where(blob_id: @blob.id).delete_all
          Panda::Core::FileCategorization.where(blob_id: @blob.id).delete_all
          @blob.purge

          redirect_to admin_cms_files_path, notice: "File was successfully deleted.", status: :see_other
        end

        private

        def set_blob
          @blob = ActiveStorage::Blob.find(params[:id])
        end

        def set_initial_breadcrumb
          add_breadcrumb "Files", admin_cms_files_path
        end

        def create_from_editor
          file = params[:image]
          return render json: {success: 0} unless file

          blob = find_existing_blob(file) || ActiveStorage::Blob.create_and_upload!(
            io: file,
            filename: file.original_filename,
            content_type: file.content_type
          )

          stamp_uploader(blob)

          render json: {
            success: true,
            file: {
              url: Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true),
              name: blob.filename.to_s,
              size: blob.byte_size
            }
          }
        end

        def create_file_from_editor
          file = params[:file]
          return render json: {success: 0} unless file

          blob = find_existing_blob(file) || ActiveStorage::Blob.create_and_upload!(
            io: file,
            filename: file.original_filename,
            content_type: file.content_type
          )

          stamp_uploader(blob)

          extension = File.extname(blob.filename.to_s).delete_prefix(".")

          render json: {
            success: 1,
            file: {
              url: Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true),
              name: blob.filename.to_s,
              size: blob.byte_size,
              extension: extension
            }
          }
        end

        def find_existing_blob(file)
          checksum = Digest::MD5.file(file.tempfile.path).base64digest
          ActiveStorage::Blob.find_by(checksum: checksum, byte_size: file.size)
        end

        def stamp_uploader(blob)
          return unless current_user
          metadata = blob.metadata || {}
          metadata["uploaded_by_id"] = current_user.id
          metadata["uploaded_by_name"] = current_user.name
          blob.update_column(:metadata, metadata)
        end

        def update_file_category(category_id)
          Panda::Core::FileCategorization.where(blob_id: @blob.id).destroy_all
          return if category_id.blank?

          category = Panda::Core::FileCategory.find_by(id: category_id)
          Panda::Core::FileCategorization.create!(file_category: category, blob: @blob) if category
        end
      end
    end
  end
end
