# frozen_string_literal: true

require "system_helper"

RSpec.describe "Files Gallery", type: :system, skip: "File gallery feature not yet implemented - see GitHub issue #149" do
  fixtures :all

  before do
    login_as_admin
    Panda::CMS::Current.root = Capybara.app_host
  end

  describe "viewing the files gallery" do
    it "shows the files page" do
      visit "/admin/cms/files"

      expect(page).to have_content("Files", wait: 10)
    end

    it "displays uploaded files in a grid" do
      # Create some test files
      3.times do |i|
        ActiveStorage::Blob.create_and_upload!(
          io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
          filename: "test_#{i}.png",
          content_type: "image/png"
        )
      end

      visit "/admin/cms/files"

      # Should show files in a grid
      expect(page).to have_css("ul[role='list']", wait: 10)
      expect(page).to have_css("li", minimum: 3)
    end

    it "shows file thumbnails for images" do
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
        filename: "thumbnail_test.png",
        content_type: "image/png"
      )

      visit "/admin/cms/files"

      # Should show image thumbnail
      expect(page).to have_css("img[alt='thumbnail_test.png']", wait: 10)
    end

    it "shows file icon for non-image files" do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("test content"),
        filename: "document.pdf",
        content_type: "application/pdf"
      )

      visit "/admin/cms/files"

      # Should show file icon (SVG) instead of image
      expect(page).to have_css("svg", wait: 10)
      expect(page).to have_content("pdf", wait: 5)
    end

    it "shows file name and size for each file" do
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
        filename: "detailed_file.png",
        content_type: "image/png"
      )

      visit "/admin/cms/files"

      expect(page).to have_content("detailed_file.png", wait: 10)
      # Should show human-readable file size
      expect(page).to have_content(/\d+\s*(Bytes|KB|MB)/i)
    end
  end

  describe "empty state" do
    before do
      # Clear all blobs
      ActiveStorage::Blob.all.each(&:purge)
    end

    it "shows empty state when no files exist" do
      visit "/admin/cms/files"

      expect(page).to have_content("No files", wait: 10)
      expect(page).to have_content("Get started by uploading a file")
    end

    it "shows upload icon in empty state" do
      visit "/admin/cms/files"

      # Should show the image/file icon in empty state
      expect(page).to have_css("svg", wait: 10)
    end
  end

  describe "file selection" do
    let!(:test_blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
        filename: "selectable_file.png",
        content_type: "image/png"
      )
    end

    it "opens slideover when clicking a file" do
      visit "/admin/cms/files"

      # Wait for file to appear
      expect(page).to have_content("selectable_file.png", wait: 10)

      # Click the file
      find("button[data-action='click->file-gallery#selectFile']", match: :first).click

      # Slideover should open
      expect(page).to have_css("#slideover", visible: true, wait: 5)
    end

    it "shows file details in slideover" do
      visit "/admin/cms/files"
      expect(page).to have_content("selectable_file.png", wait: 10)

      find("button[data-action='click->file-gallery#selectFile']", match: :first).click

      within("#slideover", wait: 5) do
        expect(page).to have_content("File Details")
        expect(page).to have_content("selectable_file.png")
      end
    end

    it "highlights selected file" do
      visit "/admin/cms/files"
      expect(page).to have_content("selectable_file.png", wait: 10)

      file_button = find("button[data-action='click->file-gallery#selectFile']", match: :first)
      file_container = file_button.find(:xpath, "ancestor::div[contains(@class, 'group')]")

      # Click to select
      file_button.click

      # Container should have selection styling
      expect(file_container[:class]).to include("outline")
    end

    it "can select different files" do
      # Create multiple files
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("test content 2"),
        filename: "second_file.txt",
        content_type: "text/plain"
      )

      visit "/admin/cms/files"

      # Select first file
      all("button[data-action='click->file-gallery#selectFile']").first.click
      expect(page).to have_css("#slideover", visible: true, wait: 5)

      # Select second file
      all("button[data-action='click->file-gallery#selectFile']").last.click

      within("#slideover") do
        expect(page).to have_content("second_file.txt")
      end
    end
  end

  describe "file gallery controller" do
    it "connects the file-gallery controller" do
      visit "/admin/cms/files"

      controller_connected = page.evaluate_script("
        const gallery = document.querySelector('[data-controller=\"file-gallery\"]');
        gallery && gallery.hasAttribute('data-controller')
      ")

      expect(controller_connected).to be true
    end

    it "has the FileGalleryComponent rendering" do
      visit "/admin/cms/files"

      # Check that the component is rendered (has the grid structure)
      expect(page).to have_css("ul[role='list']", wait: 10)
    end
  end

  describe "file metadata" do
    it "displays file creation date" do
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
        filename: "dated_file.png",
        content_type: "image/png"
      )

      visit "/admin/cms/files"
      expect(page).to have_content("dated_file.png", wait: 10)

      find("button[data-action='click->file-gallery#selectFile']", match: :first).click

      within("#slideover", wait: 5) do
        # Should show creation date in some format
        expect(page).to have_content(/\d{4}/)
      end
    end

    it "displays file content type" do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("test content"),
        filename: "typed_file.pdf",
        content_type: "application/pdf"
      )

      visit "/admin/cms/files"
      expect(page).to have_content("typed_file.pdf", wait: 10)

      find("button[data-action='click->file-gallery#selectFile']", match: :first).click

      within("#slideover", wait: 5) do
        expect(page).to have_content("application/pdf")
      end
    end

    it "displays file URL" do
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
        filename: "url_file.png",
        content_type: "image/png"
      )

      visit "/admin/cms/files"
      expect(page).to have_content("url_file.png", wait: 10)

      find("button[data-action='click->file-gallery#selectFile']", match: :first).click

      within("#slideover", wait: 5) do
        # Should show a URL path
        expect(page).to have_content(/\/rails\//)
      end
    end
  end

  describe "accessibility" do
    it "has proper ARIA labels for file buttons" do
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
        filename: "accessible_file.png",
        content_type: "image/png"
      )

      visit "/admin/cms/files"

      button = find("button[data-action='click->file-gallery#selectFile']", match: :first)
      # Should have screen reader text
      expect(button).to have_css(".sr-only", text: /View details/)
    end

    it "has proper heading for gallery" do
      visit "/admin/cms/files"

      # Should have an h2 heading for the gallery
      expect(page).to have_css("h2#gallery-heading", visible: :hidden)
      expect(page).to have_css("h2.sr-only", text: "Files")
    end
  end

  describe "responsive design" do
    it "adjusts grid columns on mobile", driver: :cuprite_mobile do
      3.times do |i|
        ActiveStorage::Blob.create_and_upload!(
          io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
          filename: "mobile_file_#{i}.png",
          content_type: "image/png"
        )
      end

      visit "/admin/cms/files"

      # Should still show grid on mobile
      expect(page).to have_css("ul[role='list']", wait: 10)
      expect(page).to have_css("li", minimum: 3)
    end
  end

  describe "file sorting" do
    it "displays newest files first" do
      # Create files with different timestamps
      old_blob = nil

      Timecop.freeze(2.days.ago) do
        old_blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("old content"),
          filename: "old_file.txt",
          content_type: "text/plain"
        )
      end

      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("new content"),
        filename: "new_file.txt",
        content_type: "text/plain"
      )

      visit "/admin/cms/files"

      # Get all file names in order they appear
      file_names = page.all("p.truncate").map(&:text)

      # New file should appear before old file
      new_index = file_names.index("new_file.txt")
      old_index = file_names.index("old_file.txt")

      expect(new_index).to be < old_index
    end
  end
end
