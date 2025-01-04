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

    fit "allows editing plain text content of the page" do
      time = Time.now.strftime("%Y-%m-%d %H:%M:%S")

      # First ensure the iframe is loaded
      expect(page).to have_css("iframe#editablePageFrame")

      within_frame "editablePageFrame" do
        # Wait for the page content to be fully loaded
        expect(page).to have_content("About")
        expect(page).to have_content("Basic Page Layout")

        # Wait for editor initialization to complete and find the first plain text area
        first_plain_text = find('span[data-editable-kind="plain_text"][contenteditable="plaintext-only"]', match: :first, wait: 10)
        expect(first_plain_text['data-editable-kind']).to eq('plain_text')

        # Debug: Print all editable elements
        debug "Found editable elements:"
        all('[data-editable-kind]').each do |el|
          debug "  - Kind: #{el['data-editable-kind']}, Content: #{el.text}"
          debug "  - HTML: #{el['outerHTML']}"
        end

        # Set the content directly on the first plain text area
        first_plain_text.click
        first_plain_text.send_keys([:control, 'a'], [:backspace])  # Clear existing content
        first_plain_text.send_keys("Here is some plain text content #{time}")
      end

      # Save the changes
      find("a", id: "saveEditableButton").click

      # Wait for the success message to be visible
      expect(page).to have_selector('.flash-message-text', text: /updated/i, visible: true, wait: 10)

      # Verify the changes
      visit "/about"
      expect(page).to have_content("Here is some plain text content #{time}")
    end

    it "allows editing rich text content of the page" do
      time = Time.now.strftime("%Y-%m-%d %H:%M:%S")

      within_frame "editablePageFrame" do
        # Wait for rich text area to be present and click into it
        rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)
        rich_text_area.click

        # Type content like a user would
        rich_text_area.send_keys([:control, 'a'], [:backspace])  # Clear existing content
        rich_text_area.send_keys("New rich text content #{time}")
      end

      # Click the save button
      find("a", id: "saveEditableButton").click

      # Wait for the success message to be visible
      expect(page).to have_selector('.flash-message-text', text: /updated/i, visible: true, wait: 10)

      # Visit the page and verify the rendered content
      visit "/about"
      expect(page).to have_content("New rich text content #{time}")
    end

    it "allows editing code content of the page" do
      time = Time.now.strftime("%Y-%m-%d %H:%M:%S")

      within_frame "editablePageFrame" do
        # Wait for HTML area to be present and click into it
        html_area = find('div[data-editable-kind="html"]', wait: 10)
        html_area.click

        # Type content like a user would
        html_area.send_keys([:control, 'a'], [:backspace])  # Clear existing content
        html_area.send_keys("<h1>New code content #{time}</h1>")
        html_area.send_keys(:enter)
        html_area.send_keys("<p>Some paragraph from code block</p>")
      end

      # Click the save button
      find("a", id: "saveEditableButton").click

      # Wait for the success message to be visible
      expect(page).to have_selector('.flash-message-text', text: /updated/i, visible: true, wait: 10)

      # Visit the page and verify the rendered content
      visit "/about"
      expect(page).to have_content("New code content #{time}")
      expect(page).to have_content("Some paragraph from code block")
    end
  end
end
