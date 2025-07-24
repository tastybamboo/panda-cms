# frozen_string_literal: true

require "system_helper"

RSpec.describe "When adding a page", type: :system, js: true do
  fixtures :all

  let(:homepage) { panda_cms_pages(:homepage) }
  let(:about_page) { panda_cms_pages(:about_page) }

  context "when not logged in" do
    it "returns a 404 error" do
      visit "/admin/pages/#{homepage.id}/edit"
      expect(page.html).to include("The page you were looking for doesn't exist.")
    end
  end

  context "when not logged in as an administrator" do
    it "returns a 404 error" do
      login_as_user
      visit "/admin/pages/#{homepage.id}/edit"
      expect(page.html).to include("The page you were looking for doesn't exist.")
    end
  end

  context "when logged in as an administrator" do
    context "when using the add page form" do
      before(:each) do
        login_as_admin
        visit "/admin/pages/new"
      end

      it "shows the add page form" do
        expect(page.html).to include("Add Page")
        expect(page).to have_field("Title")
        expect(page).to have_field("URL")
        expect(page).to have_field("Template")
      end

      it "can access the new page route" do
        expect(page.current_url).to include("/admin/pages/new")
        expect(page.status_code).to eq(200)
      end

      it "creates a new page with valid details and redirects to the page editor" do
        expect(page).to have_field("URL", with: "")
        trigger_slug_generation("New Test Page")
        expect(page).to have_field("URL", with: "/new-test-page")
        select "Page", from: "Template"
        click_button "Create Page"

        within_frame "editablePageFrame" do
          expect(page.html).to include("Basic Page Layout")
        end
      end

      it "shows validation errors with a URL that has already been used" do
        expect(page).to have_field("URL", with: "")
        fill_in "Title", with: "About Duplicate"
        fill_in "URL", with: "/about"
        select "Page", from: "Template"
        click_button "Create Page"
        expect(page.html).to include("URL has already been taken")
      end

      it "updates the form if a parent page is selected" do
        expect(page).to have_select("Parent", wait: 5)
        select "- About", from: "Parent"
        # Without JavaScript, manually create a child page
        fill_in "Title", with: "Child Page"
        fill_in "URL", with: "/about/child-page"
        expect(page).to have_field("URL", with: "/about/child-page")
      end

      it "allows a page to have the same slug as another as long as the parent is different" do
        expect(page).to have_field("URL", with: "")
        select "- About", from: "Parent"
        trigger_slug_generation("About")
        expect(page).to have_field("URL", with: "/about/about")
        select "Page", from: "Template"
        click_button "Create Page"
        expect(page.html).to_not include("URL has already been taken")
        expect(page.html).to_not include("URL has already been taken in this section")

        within_frame "editablePageFrame" do
          expect(page.html).to include("Basic Page Layout")
        end
      end

      it "doesn't show the homepage template as selectable as it has already been used" do
        expect(page).to have_select("Template", options: ["Page", "Different Page"])
        expect(page).to_not have_select("Template", with_options: ["Homepage"])
      end

      it "shows validation errors with an incorrect URL" do
        fill_in "Title", with: "New Test Page"
        fill_in "URL", with: "new-test-page"
        click_button "Create Page"
        expect(page.html).to include("URL must start with a forward slash")
      end

      it "shows validation errors with no title", :flaky do
        fill_in "URL", with: "/new-test-page"
        click_button "Create Page"
        expect(page.html).to include("Title can't be blank")
      end

      it "shows validation errors with no URL" do
        fill_in "Title", with: "A Test Page"
        # Trigger the URL autofill
        click_on_selectors "input#page_title", "input#page_path"
        # Then explicitly clear the URL
        fill_in "URL", with: ""
        click_button "Create Page"
        expect(page.html).to include("URL can't be blank and must start with a forward slash")
      end

      it "shows validation errors with invalid details", :flaky do
        expect(page).to have_button("Create Page", wait: 5)
        click_button "Create Page"
        expect(page.html).to include("Title can't be blank")
        expect(page.html).to include("URL can't be blank and must start with a forward slash")
      end

      context "when creating nested pages" do
        it "correctly generates slugs for second-level pages without path duplication" do
          # Create a first-level page
          trigger_slug_generation("First Level Page")
          expect(page).to have_field("URL", with: "/first-level-page")
          select "Page", from: "Template"
          click_button "Create Page"

          within_frame "editablePageFrame" do
            expect(page.html).to include("Basic Page Layout")
          end

          # Now create a second-level page under the first-level page
          visit "/admin/pages/new"
          select "- First Level Page", from: "Parent"
          trigger_slug_generation("Second Level Page")
          expect(page).to have_field("URL", with: "/first-level-page/second-level-page")
          select "Page", from: "Template"
          click_button "Create Page"

          # Verify the page was created with the correct path
          expect(page.html).to_not include("URL has already been taken")
          within_frame "editablePageFrame" do
            expect(page.html).to include("Basic Page Layout")
          end

          # Verify the actual path stored in the database
          second_level_page = Panda::CMS::Page.find_by(title: "Second Level Page")
          expect(second_level_page.path).to eq("/first-level-page/second-level-page")
        end

        it "correctly generates slugs for third-level pages without path duplication" do
          # Create a first-level page
          trigger_slug_generation("Level One")
          select "Page", from: "Template"
          click_button "Create Page"

          # Create a second-level page
          visit "/admin/pages/new"
          select "- Level One", from: "Parent"
          trigger_slug_generation("Level Two")
          select "Page", from: "Template"
          click_button "Create Page"

          # Create a third-level page
          visit "/admin/pages/new"
          select "-- Level Two", from: "Parent"
          trigger_slug_generation("Level Three")
          expect(page).to have_field("URL", with: "/level-one/level-two/level-three")
          select "Page", from: "Template"
          click_button "Create Page"

          # Verify the page was created successfully
          expect(page.html).to_not include("URL has already been taken")
          within_frame "editablePageFrame" do
            expect(page.html).to include("Basic Page Layout")
          end

          # Verify the actual path stored in the database
          third_level_page = Panda::CMS::Page.find_by(title: "Level Three")
          expect(third_level_page.path).to eq("/level-one/level-two/level-three")
        end
      end
    end

    context "when navigating from pages index" do
      before(:each) do
        login_as_admin
        visit "/admin/pages"
      end

      it "can access the pages index first" do
        expect(page.status_code).to eq(200)
        expect(page.html).to include("Pages")
      end

      it "shows validation errors when adding a page with invalid details", :flaky do
        click_on "Add Page"

        expect(page).to have_field("Title", wait: 5)
        fill_in "Title", with: "Test Page"
        fill_in "URL", with: "invalid-url"
        click_on "Create Page"

        expect(page.html).to include("URL must start with a forward slash")
      end

      it "shows validation errors when adding a page with missing title input", :flaky do
        click_on "Add Page"

        expect(page).to have_field("URL", wait: 5)
        fill_in "URL", with: "/test-page"
        click_on "Create Page"

        expect(page.html).to include("Title can't be blank")
      end

      it "shows validation errors when adding a page with missing URL input", :flaky do
        click_on "Add Page"

        expect(page).to have_field("Title", wait: 5)
        fill_in "Title", with: "Test Page"
        fill_in "URL", with: ""
        click_on "Create Page"

        expect(page.html).to include("URL can't be blank and must start with a forward slash")
      end
    end
  end
end
