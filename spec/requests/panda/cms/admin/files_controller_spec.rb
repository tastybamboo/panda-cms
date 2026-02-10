# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Files", type: :request do
  include ActiveJob::TestHelper

  let(:admin_user) { create_admin_user }
  let!(:category) { Panda::Core::FileCategory.create!(name: "Test Category", slug: "test-category") }

  before do
    post "/admin/test_sessions", params: {user_id: admin_user.id}
  end

  describe "GET /admin/cms/files" do
    it "excludes variant blobs from the listing" do
      # Create an original blob
      original = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("original"),
        filename: "original.jpg",
        content_type: "image/jpeg"
      )

      # Create a variant record with its own blob (simulating what ActiveStorage does)
      variant_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("variant"),
        filename: "variant.jpg",
        content_type: "image/jpeg"
      )
      variant_record = ActiveStorage::VariantRecord.create!(blob: original, variation_digest: "test_digest")
      variant_record.image.attach(variant_blob)

      get "/admin/cms/files"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("original.jpg")
      expect(response.body).not_to include(">variant.jpg<")
    end
  end

  describe "GET /admin/cms/files with category filter" do
    it "filters files by category" do
      categorized_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("categorized"),
        filename: "categorized.txt",
        content_type: "text/plain"
      )
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("uncategorized"),
        filename: "uncategorized.txt",
        content_type: "text/plain"
      )
      Panda::Core::FileCategorization.create!(file_category: category, blob: categorized_blob)

      get "/admin/cms/files", params: {category: "test-category"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("categorized.txt")
      expect(response.body).not_to include("uncategorized.txt")
    end

    it "filters to uncategorized files" do
      tagged_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("tagged"),
        filename: "tagged_file.txt",
        content_type: "text/plain"
      )
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("loose"),
        filename: "loose_file.txt",
        content_type: "text/plain"
      )
      Panda::Core::FileCategorization.create!(file_category: category, blob: tagged_blob)

      get "/admin/cms/files", params: {category: "uncategorized"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("loose_file.txt")
      expect(response.body).not_to include("tagged_file.txt")
    end

    it "shows all files when no category filter" do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("any file"),
        filename: "any_file.txt",
        content_type: "text/plain"
      )

      get "/admin/cms/files"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("any_file.txt")
    end
  end

  describe "DELETE /admin/cms/files/:id" do
    it "deletes a blob with no attachments" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("delete me"),
        filename: "delete_me.txt",
        content_type: "text/plain"
      )

      perform_enqueued_jobs do
        expect {
          delete "/admin/cms/files/#{blob.id}"
        }.to change(ActiveStorage::Blob, :count).by(-1)
      end

      expect(response).to redirect_to("/admin/cms/files")
    end

    it "deletes a blob that has active attachments" do
      admin_user.avatar.attach(
        io: StringIO.new("avatar data"),
        filename: "avatar.jpg",
        content_type: "image/jpeg"
      )
      blob = admin_user.avatar.blob

      perform_enqueued_jobs do
        expect {
          delete "/admin/cms/files/#{blob.id}"
        }.to change(ActiveStorage::Blob, :count).by(-1)
          .and change(ActiveStorage::Attachment, :count).by(-1)
      end

      expect(response).to redirect_to("/admin/cms/files")
    end

    it "deletes a blob that has variant records" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("image data"),
        filename: "with_variants.jpg",
        content_type: "image/jpeg"
      )
      variant_record = ActiveStorage::VariantRecord.create!(blob: blob, variation_digest: "test_digest")
      variant_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("variant data"),
        filename: "variant.jpg",
        content_type: "image/jpeg"
      )
      variant_record.image.attach(variant_blob)

      perform_enqueued_jobs do
        expect {
          delete "/admin/cms/files/#{blob.id}"
        }.to change(ActiveStorage::Blob, :count).by(-2)
          .and change(ActiveStorage::VariantRecord, :count).by(-1)
      end

      expect(response).to redirect_to("/admin/cms/files")
    end

    it "also removes associated file categorizations" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("categorized"),
        filename: "categorized.txt",
        content_type: "text/plain"
      )
      Panda::Core::FileCategorization.create!(file_category: category, blob: blob)

      expect {
        delete "/admin/cms/files/#{blob.id}"
      }.to change(Panda::Core::FileCategorization, :count).by(-1)

      expect(response).to redirect_to("/admin/cms/files")
    end
  end

  describe "POST /admin/cms/files (gallery upload)" do
    it "stamps the uploader metadata on the blob" do
      file = Rack::Test::UploadedFile.new(
        StringIO.new("test content"),
        "text/plain",
        original_filename: "test.txt"
      )

      post "/admin/cms/files", params: {
        file_upload: {file: file, file_category_id: category.id}
      }

      blob = ActiveStorage::Blob.order(created_at: :desc).first
      expect(blob.metadata["uploaded_by_id"]).to eq(admin_user.id)
      expect(blob.metadata["uploaded_by_name"]).to eq(admin_user.name)
    end
  end
end
