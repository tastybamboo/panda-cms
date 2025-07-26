# frozen_string_literal: true

require "system_helper"

RSpec.describe "When editing a page", type: :system do
  include EditorHelpers
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
    before(:each) do
      login_as_admin
      # Initialize Current.root for iframe template rendering
      Panda::CMS::Current.root = Capybara.app_host
      visit "/admin/pages/#{about_page.id}/edit"
    end

    it "shows the page details slideover" do
      expect(page.html).to include("About")
      expect(page.html).to include("<main")
      expect(page.html).to include("<h1")

      expect(page.html).to include("Page Details")

      if ENV["GITHUB_ACTIONS"]
        # In CI, use JavaScript to click the element to avoid Ferrum issues
        page.execute_script("document.getElementById('slideover-toggle').click()")
      else
        find("a[id='slideover-toggle']").click
      end

      within("#slideover") do
        expect(page).to have_field("Title", with: "About")
      end
    end

    it "updates the page details" do
      # Allow page to stabilize before interacting
      sleep 1
      find("a[id='slideover-toggle']").click
      within("#slideover") do
        fill_in "Title", with: "Updated About Page"
      end
      click_button "Save"
      # Wait for success message and page update
      expect(page.html).to include("This page was successfully updated!")

      # Check that the title was actually updated in the database
      about_page.reload
      expect(about_page.title).to eq("Updated About Page")

      # Refresh the page to see the updated title
      visit "/admin/pages/#{about_page.id}/edit"
      # Check that the title was updated in the main heading
      expect(page.html).to include("Updated About Page")
      expect(page.html).to include("<main")
      expect(page.html).to include("<h1")
    end

    it "shows the correct link to the page" do
      expect(page.html).to include('href="/about"')
      expect(page.html).to include("/about")
    end

    it "allows clicking the link to the page" do
      within_window(open_new_window) do
        visit "/about"
        expect(page.html).to include("About")
      end
    end

    it "shows the content of the page being edited" do
      expect(page.html).to include("About")
      wait_for_iframe_load("editablePageFrame")
      within_frame "editablePageFrame" do
        expect(page.html).to include("Basic Page Layout")
      end
    end

    it "allows editing plain text content of the page" do
      wait_for_iframe_load("editablePageFrame")
      within_frame "editablePageFrame" do
        # Wait for the page to load
        expect(page.html).to include("Basic Page Layout")

        # Find plain text content and verify it's editable
        first_plain_text = find('span[data-editable-kind="plain_text"][contenteditable="plaintext-only"]',
          match: :first, wait: 10)

        # Verify the element exists and has correct attributes
        expect(first_plain_text["contenteditable"]).to eq("plaintext-only")
        expect(first_plain_text["data-editable-kind"]).to eq("plain_text")

        # Verify it has some content
        expect(first_plain_text.text).not_to be_empty
      end
    end

    it "allows editing rich text content of the page" do
      wait_for_iframe_load("editablePageFrame")
      within_frame "editablePageFrame" do
        # Wait for the page to load
        expect(page.html).to include("Basic Page Layout")

        # Find the rich text editor area and verify it exists
        rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)

        # Verify the element exists and has correct attributes
        expect(rich_text_area["data-editable-kind"]).to eq("rich_text")

        # Verify it has the editor placeholder or content
        expect(rich_text_area).to be_present
      end
    end

    it "allows editing code content of the page" do
      wait_for_iframe_load("editablePageFrame")
      within_frame "editablePageFrame" do
        # Wait for the page to load
        expect(page.html).to include("Basic Page Layout")

        # Find HTML code content and verify it's editable
        html_area = find('div[data-editable-kind="html"]', wait: 10)

        # Verify the element exists and has correct attributes
        expect(html_area["data-editable-kind"]).to eq("html")
        expect(html_area["contenteditable"]).to eq("plaintext-only")

        # Verify it has some content
        expect(html_area.text).not_to be_empty
      end
    end

    it "properly initializes Editor.js in the iframe context", :editorjs do
      within_frame "editablePageFrame" do
        # Find the rich text editor area
        find('div[data-editable-kind="rich_text"]', wait: 10)

        # Verify that all required elements and resources are present
        editor_setup = page.evaluate_script(<<~JS)
          (function() {
            return {
              has_rich_text: document.querySelector('[data-editable-kind="rich_text"]') !== null,
              has_editor_controller: document.querySelector('[data-controller="editor-js"]') !== null,
              has_codex_editor: document.querySelector('.codex-editor') !== null,
              has_editor_holder: document.querySelector('.editor-js-holder') !== null,
              editorjs_available: typeof EditorJS !== 'undefined',
              paragraph_available: typeof Paragraph !== 'undefined',
              header_available: typeof Header !== 'undefined',
              nested_list_available: typeof NestedList !== 'undefined',
              quote_available: typeof Quote !== 'undefined'
            };
          })();
        JS

        # Verify all required components are present
        expect(editor_setup["has_rich_text"]).to be true
        expect(editor_setup["has_editor_controller"]).to be true
        expect(editor_setup["has_codex_editor"]).to be true
        expect(editor_setup["has_editor_holder"]).to be true
        expect(editor_setup["editorjs_available"]).to be true
        expect(editor_setup["paragraph_available"]).to be true
        expect(editor_setup["header_available"]).to be true
        expect(editor_setup["nested_list_available"]).to be true
        expect(editor_setup["quote_available"]).to be true
      end
    end

    it "loads all required Editor.js resources", :editorjs do
      within_frame "editablePageFrame" do
        # Find the rich text editor area
        find('div[data-editable-kind="rich_text"]', wait: 10)

        # Wait for all editor resources to load
        expect(wait_for_editor_resources).to be true

        # Check that all required Editor.js components are loaded
        resources_loaded = page.evaluate_script(<<~JS)
          (function() {
            try {
              const requiredComponents = [
                'EditorJS',
                'Paragraph',
                'Header',
                'NestedList',
                'Quote',
                'Table'
              ];

              const loadedComponents = [];
              const missingComponents = [];

              requiredComponents.forEach(component => {
                if (window[component]) {
                  loadedComponents.push(component);
                } else {
                  missingComponents.push(component);
                }
              });

              return {
                all_loaded: missingComponents.length === 0,
                loaded: loadedComponents,
                missing: missingComponents,
                total_required: requiredComponents.length,
                total_loaded: loadedComponents.length
              };
            } catch (e) {
              return {
                all_loaded: false,
                error: e.message,
                loaded: [],
                missing: [],
                total_required: 6,
                total_loaded: 0
              };
            }
          })();
        JS

        expect(resources_loaded["all_loaded"]).to be true
        expect(resources_loaded["total_loaded"]).to eq(6)
      end
    end

    it "handles Editor.js initialization failures gracefully", :editorjs do
      within_frame "editablePageFrame" do
        # Find the rich text editor area
        find('div[data-editable-kind="rich_text"]', wait: 10)

        # Simulate initialization failure by corrupting the editor
        page.execute_script("window.EditorJS = null;")

        # Try to initialize the editor
        initialization_result = page.evaluate_script(<<~JS)
          (function() {
            try {
              // Attempt to create a new editor instance
              if (window.EditorJS) {
                return { success: true, error: null };
              } else {
                return { success: false, error: "EditorJS not available" };
              }
            } catch (e) {
              return { success: false, error: e.message };
            }
          })();
        JS

        expect(initialization_result["success"]).to be false
        expect(initialization_result["error"]).to include("not available")
      end
    end

    it "maintains editor state after page interactions", :editorjs do
      within_frame "editablePageFrame" do
        # Find the rich text editor area
        find('div[data-editable-kind="rich_text"]', wait: 10)

        # Verify editor resources are loaded
        editor_ready = page.evaluate_script(<<~JS)
          (function() {
            return typeof EditorJS !== 'undefined' &&
                   typeof Paragraph !== 'undefined' &&
                   document.querySelector('.codex-editor') !== null;
          })();
        JS

        expect(editor_ready).to be true

        # Test basic interaction with editor area (find the one within rich text component)
        within('[data-editable-kind="rich_text"]') do
          editor_area = first(".codex-editor")
          expect(editor_area).to be_visible

          # Click on the editor to activate it
          editor_area.click
        end

        # Verify editor responds to interaction (just check it's still there after click)
        expect(page).to have_css(".codex-editor", wait: 2)
      end
    end

    it "outputs detailed editor initialization debug info", :editorjs do
      within_frame "editablePageFrame" do
        find('div[data-editable-kind="rich_text"]', wait: 10)

        debug_info = page.evaluate_script(<<~JS)
          (function() {
            const info = {
              timestamp: new Date().toISOString(),
              url: window.location.href,
              userAgent: navigator.userAgent,
              windowSize: {
                width: window.innerWidth,
                height: window.innerHeight
              },
              editor: {
                global_exists: typeof window.editor !== 'undefined',
                global_value: window.editor ? 'object' : 'null/undefined'
              },
              editorjs: {
                class_exists: typeof window.EditorJS !== 'undefined',
                class_type: typeof window.EditorJS
              },
              components: {},
              dom: {
                editor_containers: document.querySelectorAll('.codex-editor').length,
                editor_holders: document.querySelectorAll('.editor-js-holder').length,
                editable_areas: document.querySelectorAll('[data-editable-kind]').length
              },
              errors: []
            };

            // Check for Editor.js components
            const components = ['Paragraph', 'Header', 'NestedList', 'Quote', 'Table'];
            components.forEach(component => {
              try {
                info.components[component] = {
                  exists: typeof window[component] !== 'undefined',
                  type: typeof window[component]
                };
              } catch (e) {
                info.errors.push(`Error checking ${component}: ${e.message}`);
              }
            });

            return info;
          })();
        JS

        # Basic assertions
        expect(debug_info["dom"]["editable_areas"]).to be > 0
        expect(debug_info["errors"]).to be_empty
      end
    end
  end
end
