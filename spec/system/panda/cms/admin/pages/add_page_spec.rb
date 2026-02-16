# frozen_string_literal: true

require "system_helper"

RSpec.describe "When adding a page", type: :system do
  fixtures :all

  let(:homepage) { panda_cms_pages(:homepage) }
  let(:about_page) { panda_cms_pages(:about_page) }

  context "when not logged in" do
    it "returns a 404 error" do
      visit "/admin/cms/pages/#{homepage.id}/edit"
      expect(page.html).to include("Routing Error")
    end
  end

  context "when not logged in as an administrator" do
    it "returns a 404 error" do
      login_as_user
      visit "/admin/cms/pages/#{homepage.id}/edit"
      expect(page.html).to include("Routing Error")
    end
  end

  context "when logged in as an administrator" do
    context "when using the add page form" do
      before(:each) do
        login_as_admin
        visit "/admin/cms/pages/new"
        # Wait for form to be ready
        expect(page).to have_css("form", wait: 5)
        # Use page.html check instead of have_content to avoid Ferrum issues
        expect(page.html).to include("Add Page")
      end

      it "shows the add page form" do
        html_content = page.html
        expect(html_content).to include("Add Page")
        expect(html_content).to include("Title")
        expect(html_content).to include("URL")
        expect(html_content).to include("Template")
      end

      it "can access the new page route" do
        expect(page.current_url).to include("/admin/cms/pages/new")
        # Check for successful page load
        expect(page.status_code).to eq(200)
        expect(page).to have_css("form", wait: 5)
      end

      it "creates a new page with valid details and redirects to the page editor" do
        trigger_slug_generation("New Test Page")
        # Wait for slug field to be populated
        expect(page).to have_field("page_path", with: /\/new-test-page/, wait: 2)
        select "Page", from: "page_panda_cms_template_id"
        click_button "Create Page"

        wait_for_iframe_load("editablePageFrame")
        within_frame "editablePageFrame" do
          expect(page).to have_content("Basic Page Layout")
        end
      end

      it "shows validation errors with a URL that has already been used" do
        fill_in "page_title", with: "About Duplicate"
        fill_in "page_path", with: "/about"
        select "Page", from: "page_panda_cms_template_id"
        click_button "Create Page"
        expect(page).to have_content("URL has already been taken", wait: 5)
      end

      it "updates the form if a parent page is selected" do
        # Parent select should be present
        select "- About", from: "page_parent_id"
        # Without JavaScript, manually create a child page
        fill_in "page_title", with: "Child Page"
        fill_in "page_path", with: "/about/child-page"
        # Path field should have the correct value
      end

      it "allows a page to have the same slug as another as long as the parent is different" do
        # Form is already loaded from before block
        expect(page.html).to include("Add Page")
        if ENV["GITHUB_ACTIONS"]
          safe_select "- About", from: "page_parent_id"
          trigger_slug_generation("About")
          # Wait for slug field to be populated
          expect(page).to have_field("page_path", with: /\/about\/about/, wait: 2)
          safe_select "Page", from: "page_panda_cms_template_id"
          safe_click_button "Create Page"
        else
          select "- About", from: "page_parent_id"
          trigger_slug_generation("About")
          # Wait for slug field to be populated
          expect(page).to have_field("page_path", with: /\/about\/about/, wait: 2)
          select "Page", from: "page_panda_cms_template_id"
          click_button "Create Page"
        end
        expect(page).not_to have_content("URL has already been taken")
        expect(page).not_to have_content("URL has already been taken in this section")

        wait_for_iframe_load("editablePageFrame")
        within_frame "editablePageFrame" do
          expect(page).to have_content("Basic Page Layout")
        end
      end

      it "doesn't show the homepage template as selectable as it has already been used" do
        # Template select should show available templates
        expect(page.html).to include("Page")
        expect(page.html).to include("Different Page")

        # Homepage template has max_uses: 1 and pages_count: 1 in fixtures
        # so it should NOT be available in the template dropdown
        # Note: We check for exact option text, not partial match, since
        # "Sanctuary Homepage" is a different template that should be allowed
        template_select = find("#page_panda_cms_template_id")
        option_texts = template_select.all("option").map(&:text)
        expect(option_texts).not_to include("Homepage")
      end

      it "shows validation errors with an incorrect URL" do
        fill_in "page_title", with: "New Test Page"
        fill_in "page_path", with: "new-test-page"
        click_button "Create Page"

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
        fill_in "page_title", with: "A Test Page"
        # Clear the path field to test validation
        fill_in "page_path", with: ""
        click_button "Create Page"

        # Check for validation error
        expect(page).to have_content("URL can't be blank and must start with a forward slash", wait: 5)
      end

      it "shows validation errors with invalid details" do
        expect(page).to have_button("Create Page", wait: 5)
        click_button "Create Page"

        # Check for validation errors
        expect(page).to have_content("Title can't be blank", wait: 5)
        expect(page).to have_content("URL can't be blank and must start with a forward slash")
      end

      context "when creating nested pages" do
        it "correctly generates slugs for second-level pages without path duplication" do
          # Create a first-level page
          trigger_slug_generation("First Level Page")
          # Wait for slug field to be populated
          expect(page).to have_field("page_path", with: /\/first-level-page/, wait: 2)
          select "Page", from: "page_panda_cms_template_id"
          click_button "Create Page"

          wait_for_iframe_load("editablePageFrame")
          within_frame "editablePageFrame" do
            expect(page.html).to include("Basic Page Layout")
          end

          # Now create a second-level page under the first-level page
          visit "/admin/cms/pages/new"
          expect(page).to have_css("form", wait: 5)
          select "- First Level Page", from: "page_parent_id"
          trigger_slug_generation("Second Level Page")
          # Wait for slug field to be populated with correct nested path
          expect(page).to have_field("page_path", with: /\/first-level-page\/second-level-page/, wait: 2)
          select "Page", from: "page_panda_cms_template_id"
          click_button "Create Page"

          # Verify the page was created with the correct path
          expect(page.html).to_not include("URL has already been taken")
          wait_for_iframe_load("editablePageFrame")
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
          if ENV["GITHUB_ACTIONS"]
            safe_select "Page", from: "page_panda_cms_template_id"
            safe_click_button "Create Page"
          else
            select "Page", from: "page_panda_cms_template_id"
            click_button "Create Page"
          end

          # Create a second-level page
          visit "/admin/cms/pages/new"
          expect(page).to have_css("form", wait: 5)
          select "- Level One", from: "page_parent_id"
          trigger_slug_generation("Level Two")
          select "Page", from: "page_panda_cms_template_id"
          click_button "Create Page"

          # Create a third-level page
          visit "/admin/cms/pages/new"
          expect(page).to have_css("form", wait: 5)
          select "-- Level Two", from: "page_parent_id"
          trigger_slug_generation("Level Three")
          # Wait for slug field to be populated with correct nested path
          expect(page).to have_field("page_path", with: /\/level-one\/level-two\/level-three/, wait: 2)
          select "Page", from: "page_panda_cms_template_id"
          click_button "Create Page"

          # Verify the page was created successfully
          expect(page.html).to_not include("URL has already been taken")
          wait_for_iframe_load("editablePageFrame")
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
        visit "/admin/cms/pages"
      end

      it "can access the pages index first" do
        # Check for successful page load
        expect(page.status_code).to eq(200)
        expect(page.html).to include("Pages")
        # TableComponent uses CSS table classes, not HTML table elements
        expect(page).to have_css(".table", wait: 5)
      end

      it "shows validation errors when adding a page with invalid details" do
        visit "/admin/cms/pages/new"
        expect(page).to have_css("form", wait: 5)
        fill_in "page_title", with: "Test Page"
        fill_in "page_path", with: "invalid-url"
        click_on "Create Page"

        # Check for validation error
        expect(page).to have_content("URL must start with a forward slash", wait: 5)
      end

      it "shows validation errors when adding a page with missing title input" do
        visit "/admin/cms/pages/new"
        expect(page).to have_css("form", wait: 5)
        fill_in "page_path", with: "/test-page"
        click_on "Create Page"

        # Check for validation error
        expect(page).to have_content("Title can't be blank", wait: 5)
      end

      it "shows validation errors when adding a page with missing URL input" do
        visit "/admin/cms/pages/new"
        expect(page).to have_css("form", wait: 5)
        fill_in "page_title", with: "Test Page"
        fill_in "page_path", with: ""
        click_on "Create Page"

        # Check for validation error
        expect(page).to have_content("URL can't be blank and must start with a forward slash", wait: 5)
      end
    end
  end
end
