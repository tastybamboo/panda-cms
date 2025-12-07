# frozen_string_literal: true

require "system_helper"

# TODO: These tests are currently failing due to page rendering issues
# See: https://github.com/tastybamboo/panda-cms/issues/150
# All 15 tests fail with "about:blank" page - needs investigation
# IMPORTANT: Tests must be skipped at top level to prevent before hooks from polluting browser state
RSpec.describe "Page form SEO functionality", type: :system do
  fixtures :all

  let(:homepage) { panda_cms_pages(:homepage) }
  let(:about_page) { panda_cms_pages(:about_page) }

  before do
    login_as_admin
    Panda::CMS::Current.root = Capybara.app_host
  end

  def open_page_details
    visit "/admin/cms/pages/#{about_page.id}/edit"
    expect(page).to have_content("About", wait: 10)

    # Click the Page Details button to open the slideover
    click_button "Page Details"

    # Give JavaScript time to execute
    sleep 0.5

    expect(page).to have_css("#slideover", visible: true, wait: 5)
  end

  describe "character counters" do
    context "when inherit is not checked" do
      before do
        # Ensure inherit is disabled so fields are editable
        about_page.update!(inherit_seo: false)
      end

      it "shows character count for SEO title field" do
        open_page_details

        within("#slideover") do
          seo_title_field = find_field("SEO Title")
          container = seo_title_field.find(:xpath, "ancestor::div[contains(@class, 'panda-core-field-container')]")

          # Check counter exists
          expect(container).to have_css(".character-counter")

          # Type some text
          seo_title_field.set("Test SEO Title")

          # Wait for counter to update
          sleep 0.3

          # Check counter shows correct count
          expect(container.find(".character-counter")).to have_text("14 / 70 characters")
        end
      end

      it "shows warning when approaching character limit" do
        open_page_details

        within("#slideover") do
          seo_title_field = find_field("SEO Title")
          container = seo_title_field.find(:xpath, "ancestor::div[contains(@class, 'panda-core-field-container')]")

          # Type text close to limit (70 chars)
          seo_title_field.set("A" * 65)

          sleep 0.5

          counter = container.find(".character-counter")
          expect(counter).to have_text("65 / 70 characters")
          expect(counter[:class]).to include("text-yellow-600")
        end
      end

      it "shows error when over character limit" do
        open_page_details

        within("#slideover") do
          seo_title_field = find_field("SEO Title")
          container = seo_title_field.find(:xpath, "ancestor::div[contains(@class, 'panda-core-field-container')]")

          # Type text over limit
          seo_title_field.set("A" * 75)

          sleep 0.5

          counter = container.find(".character-counter")
          expect(counter).to have_text("75 / 70 characters (5 over limit)")
          expect(counter[:class]).to include("text-red-600")
        end
      end
    end

    context "when inherit is checked" do
      before do
        # Set up parent page with SEO values for inheritance
        homepage.update!(
          seo_title: "Parent SEO Title with 30 chars",
          seo_description: "A" * 100
        )
        # Enable inheritance for the child page
        about_page.update!(inherit_seo: true)
      end

      it "shows character count for inherited SEO title" do
        open_page_details

        within("#slideover") do
          seo_title_field = find_field("SEO Title")
          container = seo_title_field.find(:xpath, "ancestor::div[contains(@class, 'panda-core-field-container')]")

          # Field should be readonly
          expect(seo_title_field[:readonly]).to eq("true")

          # Check counter shows correct count for inherited value
          expect(container.find(".character-counter")).to have_text("30 / 70 characters")
        end
      end

      it "shows warning when inherited value approaches limit" do
        # Update parent to have value close to limit
        homepage.update!(seo_title: "A" * 65)

        open_page_details

        within("#slideover") do
          seo_title_field = find_field("SEO Title")
          container = seo_title_field.find(:xpath, "ancestor::div[contains(@class, 'panda-core-field-container')]")

          counter = container.find(".character-counter")
          expect(counter).to have_text("65 / 70 characters")
          expect(counter[:class]).to include("text-yellow-600")
        end
      end
    end
  end

  describe "auto-fill functionality" do
    before do
      # Ensure inherit is disabled so fields are editable
      about_page.update!(inherit_seo: false)
    end

    it "auto-fills SEO title from page title on blur" do
      open_page_details

      within("#slideover") do
        # Clear and change page title
        page_title_field = find_field("Title")
        page_title_field.fill_in with: "New Page Title"

        # Blur the field
        page_title_field.send_keys(:tab)

        sleep 0.5

        # Check SEO title was auto-filled
        seo_title_field = find_field("SEO Title")
        expect(seo_title_field.value).to eq("New Page Title")
      end
    end

    it "auto-fills OpenGraph title from SEO title on blur" do
      open_page_details

      within("#slideover") do
        # Fill SEO title
        seo_title_field = find_field("SEO Title")
        seo_title_field.fill_in with: "Custom SEO Title"

        # Blur the field
        seo_title_field.send_keys(:tab)

        sleep 0.5

        # Check OG title was auto-filled
        og_title_field = find_field("Social Media Title")
        expect(og_title_field.value).to eq("Custom SEO Title")
      end
    end

    it "auto-fills OpenGraph description from SEO description on blur" do
      open_page_details

      within("#slideover") do
        # Fill SEO description
        seo_desc_field = find_field("SEO Description")
        seo_desc_field.fill_in with: "This is the SEO description"

        # Blur the field
        seo_desc_field.send_keys(:tab)

        sleep 0.5

        # Check OG description was auto-filled
        og_desc_field = find_field("Social Media Description")
        expect(og_desc_field.value).to eq("This is the SEO description")
      end
    end

    it "does not overwrite existing values" do
      open_page_details

      within("#slideover") do
        # Pre-fill OG title with custom value
        og_title_field = find_field("Social Media Title")
        og_title_field.fill_in with: "My Custom OG Title"

        # Now fill SEO title
        seo_title_field = find_field("SEO Title")
        seo_title_field.fill_in with: "Different SEO Title"
        seo_title_field.send_keys(:tab)

        sleep 0.5

        # OG title should NOT have changed
        expect(og_title_field.value).to eq("My Custom OG Title")
      end
    end

    it "sets placeholders on page load for empty fields" do
      open_page_details

      within("#slideover") do
        # Check that empty SEO title has page title as placeholder
        seo_title_field = find_field("SEO Title")
        expect(seo_title_field[:placeholder]).to eq("About")

        # Check that empty OG title has fallback as placeholder
        og_title_field = find_field("Social Media Title")
        expect(og_title_field[:placeholder]).not_to be_nil
      end
    end
  end

  describe "inherit settings functionality" do
    before do
      # Set up parent page with SEO values
      homepage.update!(
        seo_title: "Parent SEO Title",
        seo_description: "Parent SEO Description",
        seo_keywords: "parent, keywords",
        canonical_url: "https://example.com/parent",
        og_title: "Parent OG Title",
        og_description: "Parent OG Description",
        og_type: "website"
      )

      # Make about_page a child of homepage
      about_page.update!(parent: homepage)
    end

    it "shows inherit checkbox for child pages" do
      open_page_details

      within("#slideover") do
        expect(page).to have_field("Inherit SEO from parent page")
      end
    end

    it "copies parent values and makes fields readonly when checked" do
      open_page_details

      within("#slideover") do
        # Check the inherit checkbox
        check "Inherit SEO from parent page"

        sleep 0.5

        # Check that fields are filled with parent values
        expect(find_field("SEO Title").value).to eq("Parent SEO Title")
        expect(find_field("SEO Description").value).to eq("Parent SEO Description")
        expect(find_field("SEO Keywords").value).to eq("parent, keywords")

        # Check that fields are readonly
        seo_title_field = find_field("SEO Title")
        expect(seo_title_field[:readonly]).to eq("true")
        expect(seo_title_field[:class]).to include("cursor-not-allowed")
      end
    end

    it "makes fields editable when unchecked" do
      open_page_details

      within("#slideover") do
        # First check it
        check "Inherit SEO from parent page"
        sleep 0.5

        # Then uncheck it
        uncheck "Inherit SEO from parent page"
        sleep 0.5

        # Check that fields are editable again
        seo_title_field = find_field("SEO Title")
        expect(seo_title_field[:readonly]).to be_nil
        expect(seo_title_field[:class]).not_to include("cursor-not-allowed")
      end
    end
  end

  describe "form validation" do
    it "shows error state when fields exceed character limits", :flaky do
      open_page_details

      within("#slideover") do
        # Fill field over limit (70 char limit for SEO Title)
        seo_title_field = find_field("SEO Title")
        seo_title_field.fill_in with: "A" * 75

        # Trigger input event to update counter
        seo_title_field.execute_script("this.dispatchEvent(new Event('input', { bubbles: true }))")

        # Wait for counter to update (increased for CI stability)
        sleep 0.5

        # Check that counter shows error state (red color for over limit)
        expect(page).to have_css(".character-counter.text-red-600", wait: 2)
      end
    end

    it "shows success state when all fields are within limits" do
      open_page_details

      within("#slideover") do
        # Fill fields within limits
        seo_title_field = find_field("SEO Title")
        seo_title_field.fill_in with: "Valid SEO Title"

        # Trigger input event
        seo_title_field.execute_script("this.dispatchEvent(new Event('input', { bubbles: true }))")

        sleep 0.3

        # Check that counter shows normal state (not red)
        expect(page).not_to have_css(".character-counter.text-red-600")
      end
    end
  end

  describe "page form controller connection" do
    it "connects the controller on page load" do
      open_page_details

      # Check that controller is connected
      controller_connected = page.evaluate_script("(() => {
        var form = document.querySelector('#page-form');
        return form && form.hasAttribute('data-controller') && form.getAttribute('data-controller').includes('page-form');
      })()")

      expect(controller_connected).to be true
    end

    it "has all required form fields available" do
      open_page_details

      within("#slideover") do
        # Check all expected form fields are present and accessible
        expect(page).to have_field("Title")
        expect(page).to have_field("SEO Title")
        expect(page).to have_field("SEO Description")
        expect(page).to have_field("Social Media Title")
        expect(page).to have_field("Social Media Description")
      end
    end
  end
end
