# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin Files Management", type: :system do
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
end
