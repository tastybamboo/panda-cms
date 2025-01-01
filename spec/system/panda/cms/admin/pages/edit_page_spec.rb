require "system_helper"

RSpec.describe "When editing a page", type: :system do
  include EditorHelpers

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
    let(:about_page) { Panda::CMS::Page.find_by(path: "/about") }

    before(:each) do
      login_as_admin
      visit "/admin/pages/#{about_page.id}/edit"
    end

    it "shows the page details slideover" do
      within("main h1") do
        expect(page).to have_content("About")
      end

      expect(page).to have_content("Page Details")

      find("a", id: "slideover-toggle").click

      within("#slideover") do
        expect(page).to have_field("Title", with: "About")
        # expect(page).to have_field("Template", with: "Page", disabled: true)
      end
    end

    it "updates the page details" do
      find("a", id: "slideover-toggle").click
      within("#slideover") do
        fill_in "Title", with: "About Page 2"
        click_button "Save"
      end
      expect(page).to have_content("This page was successfully updated")
    end

    it "shows the correct link to the page" do
      expect(page).to have_selector("a[href='/about']", text: /\/about/)
    end

    it "allows clicking the link to the page" do
      new_window = window_opened_by { click_link("/about", match: :first) }
      within_window new_window do
        expect(page).to have_current_path("/about")
      end
    end

    it "shows the content of the page being edited" do
      expect(page).to have_css("iframe#editablePageFrame")
      within_frame "editablePageFrame" do
        expect(page).to have_content("About")
        expect(page).to have_content("Basic Page Layout")
      end
    end

    it "allows editing plain text content of the page" do
      time = Time.now.strftime("%Y-%m-%d %H:%M:%S")

      within_frame "editablePageFrame" do
        plain_text_area = find('[data-editable-kind="plain_text"]')
        # Set content directly using JavaScript to avoid HTML escaping
        page.execute_script("arguments[0].textContent = arguments[1]", plain_text_area.native, "Here is some plain text content #{time}")
      end

      find("a", id: "saveEditableButton").click
      expect(page).to have_content("This page was successfully updated!")

      visit "/about"
      expect(page).to have_content("Here is some plain text content #{time}")
    end

    it "allows editing rich text content of the page" do
      time = Time.now.strftime("%Y-%m-%d %H:%M:%S")

      within_frame "editablePageFrame" do
        # Wait for rich text area to be present
        rich_text_area = find('div[data-editable-kind="rich_text"]')
        within rich_text_area do
          add_editor_paragraph("New rich text content #{time}")
        end
      end

      # Click the save button
      find("a", id: "saveEditableButton").click
      expect(page).to have_content("This page was successfully updated!")

      # Visit the page and verify the rendered content
      visit "/about"
      expect(page).to have_content("New rich text content #{time}")
    end

    it "allows editing code content of the page" do
      time = Time.now.strftime("%Y-%m-%d %H:%M:%S")

      within_frame "editablePageFrame" do
        html_area = find('div[data-editable-kind="html"]')
        html_area.click
        html_area.set("<h1>New code content #{time}</h1><p>Some paragraph from code block</p>")
      end

      find("a", id: "saveEditableButton").click
      expect(page).to have_content("This page was successfully updated!")

      visit "/about"
      expect(page).to have_content("New code content #{time}")
      expect(page).to have_content("Some paragraph from code block")
    end
  end
end
