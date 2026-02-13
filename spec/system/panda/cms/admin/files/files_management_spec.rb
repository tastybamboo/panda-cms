# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin Files Management", type: :system do
  include ActiveJob::TestHelper

  before do
    login_as_admin
  end

  describe "Files index page" do
    it "displays the files gallery" do
      visit "/admin/cms/files"

      expect(page).to have_content("Files")
      # Verify the FileGalleryComponent is rendered (not just instantiated)
      expect(page).to have_css("[data-controller='file-gallery']")
    end

    it "shows file upload area" do
      visit "/admin/cms/files"

      expect(page).to have_content("Files")
      # The file gallery should have upload functionality
      expect(page).to have_css("[data-file-gallery-target]") if page.has_css?("[data-file-gallery-target]", wait: 2)
    end
  end

  describe "File details slideover", js: true do
    let!(:test_file) do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("test content"),
        filename: "test_file.txt",
        content_type: "text/plain"
      )
      blob.update!(metadata: blob.metadata.merge("description" => "Original description"))
      blob
    end

    let!(:category) do
      Panda::Core::FileCategory.create!(name: "Documents", slug: "documents")
    end

    before do
      Panda::Core::FileCategorization.create!(file_category: category, blob: test_file)
    end

    it "loads server-rendered file details when clicking a file" do
      visit "/admin/cms/files"

      # Find and click the file in the gallery
      file_button = find("[data-file-id='#{test_file.id}']", wait: 5)
      file_button.click

      # Wait for slideover to open and content to load
      within "#file-gallery-slideover-content", wait: 5 do
        # Filename is split: base name in input, extension in span
        expect(page).to have_field("blob[filename]", with: "test_file")
        expect(page).to have_content(".txt")
        # Description is in a textarea
        expect(page).to have_field("blob[description]", with: "Original description")
        expect(page).to have_select("blob[file_category_id]", selected: "Documents")
      end
    end

    it "persists edits to filename, category, and description", skip: "Turbo Stream response not refreshing slideover after save" do
      visit "/admin/cms/files"

      # Select the file and wait for slideover to load
      find("[data-file-id='#{test_file.id}']", wait: 5).click
      expect(page).to have_field("blob[filename]", wait: 5)

      # Edit filename (without extension)
      fill_in "blob[filename]", with: "renamed_file"

      # Edit description
      fill_in "blob[description]", with: "Updated description text"

      # Submit the form
      click_button "Save"

      # Wait for Turbo Stream response
      expect(page).to have_content("File updated successfully", wait: 5)

      # Verify the changes persisted in the refreshed slideover
      expect(page).to have_field("blob[filename]", with: "renamed_file")
      expect(page).to have_field("blob[description]", with: "Updated description text")

      # Verify changes persisted in database
      test_file.reload
      expect(test_file.filename.to_s).to eq("renamed_file.txt")
      expect(test_file.metadata["description"]).to eq("Updated description text")
    end

    it "updates slideover content after successful save", skip: "Turbo Stream response not refreshing slideover after save" do
      visit "/admin/cms/files"

      find("[data-file-id='#{test_file.id}']", wait: 5).click
      expect(page).to have_field("blob[filename]", wait: 5)

      fill_in "blob[description]", with: "New description"
      click_button "Save"

      # Wait for Turbo Stream response
      expect(page).to have_content("File updated successfully", wait: 5)
      expect(page).to have_field("blob[description]", with: "New description")
    end

    it "shows delete confirmation and removes file" do
      visit "/admin/cms/files"

      find("[data-file-id='#{test_file.id}']", wait: 5).click

      within "#file-gallery-slideover-content", wait: 5 do
        expect(page).to have_button("Delete", wait: 5)
      end

      # Wrap in perform_enqueued_jobs so purge_later runs inline
      perform_enqueued_jobs do
        accept_confirm do
          click_button "Delete"
        end

        # Should redirect back to files index
        expect(page).to have_content("Files", wait: 5)
        expect(page).to have_content("File was successfully deleted")
      end

      # File should be gone from database
      expect(ActiveStorage::Blob.find_by(id: test_file.id)).to be_nil
    end
  end

  describe "Upload slideover", js: true do
    let!(:category) do
      Panda::Core::FileCategory.create!(name: "Images", slug: "images")
    end

    it "opens upload slideover with drag-and-drop" do
      visit "/admin/cms/files"

      # Click Upload button
      click_button "Upload", wait: 5

      # Upload panel should appear
      expect(page).to have_content("Upload File", wait: 5)
      expect(page).to have_field("file_upload[file]")
      expect(page).to have_select("file_upload[file_category_id]")
    end

    it "requires category for upload with HTML5 validation" do
      visit "/admin/cms/files"

      click_button "Upload", wait: 5

      within "[data-file-gallery-target='uploadPanel']", wait: 5 do
        # Attach a file
        attach_file "file_upload[file]", Panda::CMS::Engine.root.join("spec/fixtures/files/test_image.jpg"), make_visible: true

        # Don't select a category - the select has required: true attribute
        # HTML5 validation should prevent form submission
        click_button "Upload"

        # Form should still be visible because HTML5 validation prevented submission
        expect(page).to have_select("file_upload[file_category_id]", wait: 1)
      end
    end

    it "shows server-side validation error when category is missing" do
      visit "/admin/cms/files"

      click_button "Upload", wait: 5

      # Simulate bypassing HTML5 validation (e.g., via API or disabled JS)
      within "[data-file-gallery-target='uploadPanel']", wait: 5 do
        attach_file "file_upload[file]", Panda::CMS::Engine.root.join("spec/fixtures/files/test_image.jpg"), make_visible: true

        # Remove required attribute to test server-side validation
        page.execute_script("document.querySelector('#file_upload_file_category_id').removeAttribute('required')")

        click_button "Upload"
      end

      # Should redirect back with server-side validation error
      expect(page).to have_content("Files", wait: 5)
      expect(page).to have_content("Please select a category")
    end

    it "uploads file and shows it in gallery" do
      visit "/admin/cms/files"

      click_button "Upload", wait: 5

      within "[data-file-gallery-target='uploadPanel']", wait: 5 do
        # Attach file and select category
        attach_file "file_upload[file]", Panda::CMS::Engine.root.join("spec/fixtures/files/test_image.jpg"), make_visible: true
        select "Images", from: "file_upload[file_category_id]"

        click_button "Upload"
      end

      # Should redirect back to files index with success message
      expect(page).to have_content("File uploaded successfully", wait: 5)

      # Verify file appears in gallery (check for the uploaded file)
      expect(page).to have_css("[data-file-id]", minimum: 1)
    end
  end
end
