require "system_helper"

RSpec.describe "When adding a page", type: :system, js: true do
  context "when not logged in" do
    let(:homepage) { Panda::CMS::Page.find_by(path: "/") }

    it "returns a 404 error" do
      visit "/admin/pages/#{homepage.id}/edit"
      expect(page).to have_content("The page you were looking for doesn't exist.")
    end
  end

  context "when not logged in as an administrator" do
    let(:homepage) { Panda::CMS::Page.find_by(path: "/") }

    it "returns a 404 error" do
      login_as_user
      visit "/admin/pages/#{homepage.id}/edit"
      expect(page).to have_content("The page you were looking for doesn't exist.")
    end
  end

  context "when logged in as an administrator" do
    include_context "with standard pages"

    before(:each) do
      login_as_admin
      visit "/admin/pages/new"
    end

    it "shows the add page form" do
      expect(page).to have_content("Add Page")
      expect(page).to have_field("Title")
      expect(page).to have_field("URL")
      expect(page).to have_field("Template")
      expect(page).to have_button("Create Page")
    end

    it "creates a new page with valid details and redirects to the page editor" do
      expect(page).to have_field("URL", with: "")
      trigger_slug_generation("New Test Page")
      expect(page).to have_field("URL", with: "/new-test-page")
      select "Page", from: "Template"
      click_button "Create Page"

      within_frame "editablePageFrame" do
        expect(page).to have_content("Basic Page Layout")
      end
    end

    it "shows validation errors with a URL that has already been used" do
      expect(page).to have_field("URL", with: "")
      trigger_slug_generation("About Duplicate")
      expect(page).to have_field("URL", with: "/about-duplicate")
      fill_in "URL", with: "/about"
      select "Page", from: "Template"
      click_button "Create Page"
      expect(page).to have_content("URL has already been taken")
      expect(page.current_path).to eq "/admin/pages/new"
    end

    it "updates the form if a parent page is selected" do
      select "- About", from: "Parent"
      expect(page).to have_field("URL", with: /\/about\/$/)
    end

    it "allows a page to have the same slug as another as long as the parent is different" do
      expect(page).to have_field("URL", with: "")
      select "- About", from: "Parent"
      trigger_slug_generation("About")
      expect(page).to have_field("URL", with: "/about/about")
      select "Page", from: "Template"
      click_button "Create Page"
      expect(page).to_not have_content("URL has already been taken")
      expect(page).to_not have_content("URL has already been taken in this section")

      within_frame "editablePageFrame" do
        expect(page).to have_content("Basic Page Layout")
      end
    end

    it "doesn't show the homepage template as selectable as it has already been used" do
      expect(page).to have_select("Template", options: ["Page"])
      expect(page).to_not have_select("Template", options: ["Homepage"])
    end

    it "shows validation errors with an incorrect URL" do
      fill_in "Title", with: "New Test Page"
      fill_in "URL", with: "new-test-page"
      click_button "Create Page"
      expect(page).to have_content("URL must start with a forward slash")
    end

    it "shows validation errors with no title" do
      fill_in "URL", with: "/new-test-page"
      click_button "Create Page"
      expect(page).to have_content("Title can't be blank")
    end

    it "shows validation errors with no URL" do
      fill_in "Title", with: "A Test Page"
      # Trigger the URL autofill
      click_on_selectors "input#page_title", "input#page_path"
      # Then explicitly clear the URL
      fill_in "URL", with: ""
      click_button "Create Page"
      expect(page).to have_content("URL can't be blank and must start with a forward slash")
    end

    it "shows validation errors with invalid details" do
      click_button "Create Page"
      expect(page).to have_content("Title can't be blank")
      expect(page).to have_content("URL can't be blank and must start with a forward slash")
    end

    it "shows validation errors when adding a page with incorrect URL" do
      login_as_admin
      visit panda_cms.admin_pages_path
      click_on "Add Page"

      fill_in_title_and_wait_for_slug("Test Page")
      fill_in "page_path", with: "no-forward-slash"
      click_on "Create Page"

      expect(page).to have_content("URL must start with a forward slash")
    end

    it "shows validation errors when adding a page with missing title input" do
      login_as_admin
      visit panda_cms.admin_pages_path
      click_on "Add Page"

      fill_in "page_path", with: "/test-page"
      click_on "Create Page"

      expect(page).to have_content("Title can't be blank")
    end

    it "shows validation errors when adding a page with missing URL input" do
      login_as_admin
      visit panda_cms.admin_pages_path
      click_on "Add Page"

      fill_in_title_and_wait_for_slug("Test Page")
      fill_in "page_path", with: ""
      click_on "Create Page"

      expect(page).to have_content("URL can't be blank and must start with a forward slash")
    end

    it "shows validation errors when adding a page with invalid details" do
      login_as_admin
      visit panda_cms.admin_pages_path
      click_on "Add Page"

      fill_in_title_and_wait_for_slug("Test Page")
      fill_in "page_path", with: "invalid-url"
      click_on "Create Page"

      expect(page).to have_content("URL must start with a forward slash")
    end
  end
end
