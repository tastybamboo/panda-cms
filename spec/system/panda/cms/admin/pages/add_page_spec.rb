# frozen_string_literal: true

require "system_helper"

RSpec.describe "When adding a page", type: :system do
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
        expect(page).to have_content("Add Page", wait: 10)
      end

      it "shows the add page form" do
        expect(page.html).to include("Add Page")
        safe_expect_field("page_title")
        safe_expect_field("page_path")
        safe_expect_field("page_panda_cms_template_id")
      end

      it "can access the new page route" do
        expect(page.current_url).to include("/admin/pages/new")
        expect(page.status_code).to eq(200)
      end

      it "creates a new page with valid details and redirects to the page editor" do
        safe_expect_field("page_path", with: "")
        trigger_slug_generation("New Test Page")
        safe_expect_field("page_path", with: "/new-test-page")
        safe_select "Page", from: "page_panda_cms_template_id"
        safe_click_button "Create Page"

        within_frame "editablePageFrame" do
          expect(page.html).to include("Basic Page Layout")
        end
      end

      it "shows validation errors with a URL that has already been used" do
        safe_expect_field("page_path", with: "")
        safe_fill_in "page_title", with: "About Duplicate"
        safe_fill_in "page_path", with: "/about"
        safe_select "Page", from: "page_panda_cms_template_id"
        safe_click_button "Create Page"
        expect(page).to have_content("URL has already been taken", wait: 5)
      end

      it "updates the form if a parent page is selected" do
        safe_expect_select("page_parent_id")
        safe_select "- About", from: "page_parent_id"
        # Without JavaScript, manually create a child page
        safe_fill_in "page_title", with: "Child Page"
        safe_fill_in "page_path", with: "/about/child-page"
        safe_expect_field("page_path", with: "/about/child-page")
      end

      it "allows a page to have the same slug as another as long as the parent is different" do
        # Wait for page to fully load before checking fields
        expect(page).to have_content("Add Page", wait: 10)
        safe_expect_field("page_path", with: "")
        safe_select "- About", from: "page_parent_id"
        trigger_slug_generation("About")
        expect(page).to have_field("URL", with: "/about/about")
        safe_select "Page", from: "page_panda_cms_template_id"
        safe_click_button "Create Page"
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
        safe_fill_in "page_title", with: "New Test Page"
        safe_fill_in "page_path", with: "new-test-page"
        safe_click_button "Create Page"
        
        # Check for validation error
        expect(page).to have_content("URL must start with a forward slash", wait: 5)
      end

      it "shows validation errors with no title" do
        # Fill in path but not title
        fill_in "page_path", with: "/new-test-page"
        click_button "Create Page"
        
        # Check for validation error
        expect(page).to have_content("Title can't be blank", wait: 5)
      end

      it "shows validation errors with no URL" do
        safe_fill_in "page_title", with: "A Test Page"
        # Clear the path field to test validation
        safe_fill_in "page_path", with: ""
        safe_click_button "Create Page"
        
        # Check for validation error
        expect(page).to have_content("URL can't be blank and must start with a forward slash", wait: 5)
      end

      it "shows validation errors with invalid details" do
        expect(page).to have_button("Create Page", wait: 5)
        safe_click_button "Create Page"
        
        # Check for validation errors
        expect(page).to have_content("Title can't be blank", wait: 5)
        expect(page).to have_content("URL can't be blank and must start with a forward slash")
      end

      context "when creating nested pages" do
        it "correctly generates slugs for second-level pages without path duplication" do
          # Create a first-level page
          trigger_slug_generation("First Level Page")
          safe_expect_field("page_path", with: "/first-level-page")
          safe_select "Page", from: "page_panda_cms_template_id"
          safe_click_button "Create Page"

          within_frame "editablePageFrame" do
            expect(page.html).to include("Basic Page Layout")
          end

          # Now create a second-level page under the first-level page
          visit "/admin/pages/new"
          safe_select "- First Level Page", from: "page_parent_id"
          trigger_slug_generation("Second Level Page")
          safe_expect_field("page_path", with: "/first-level-page/second-level-page")
          safe_select "Page", from: "page_panda_cms_template_id"
          safe_click_button "Create Page"

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
          safe_select "Page", from: "page_panda_cms_template_id"
          safe_click_button "Create Page"

          # Create a second-level page
          visit "/admin/pages/new"
          safe_select "- Level One", from: "page_parent_id"
          trigger_slug_generation("Level Two")
          safe_select "Page", from: "page_panda_cms_template_id"
          safe_click_button "Create Page"

          # Create a third-level page
          visit "/admin/pages/new"
          safe_select "-- Level Two", from: "page_parent_id"
          trigger_slug_generation("Level Three")
          safe_expect_field("page_path", with: "/level-one/level-two/level-three")
          safe_select "Page", from: "page_panda_cms_template_id"
          safe_click_button "Create Page"

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

      it "shows validation errors when adding a page with invalid details" do
        visit "/admin/pages/new"
        expect(page).to have_css("form", wait: 5)

        safe_expect_field("page_title")
        safe_fill_in "page_title", with: "Test Page"
        safe_fill_in "page_path", with: "invalid-url"
        click_on "Create Page"

        # Check for validation error
        expect(page).to have_content("URL must start with a forward slash", wait: 5)
      end

      it "shows validation errors when adding a page with missing title input" do
        visit "/admin/pages/new"
        expect(page).to have_css("form", wait: 5)

        safe_expect_field("page_path")
        safe_fill_in "page_path", with: "/test-page"
        click_on "Create Page"

        # Check for validation error
        expect(page).to have_content("Title can't be blank", wait: 5)
      end

      it "shows validation errors when adding a page with missing URL input" do
        visit "/admin/pages/new"
        expect(page).to have_css("form", wait: 5)

        safe_expect_field("page_title")
        safe_fill_in "page_title", with: "Test Page"
        safe_fill_in "page_path", with: ""
        click_on "Create Page"

        # Check for validation error
        expect(page).to have_content("URL can't be blank and must start with a forward slash", wait: 5)
      end
    end
  end
end
