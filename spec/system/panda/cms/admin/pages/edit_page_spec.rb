require "system_helper"

RSpec.describe "When editing a page", type: :system do
  include EditorHelpers
  fixtures :all

  let(:homepage) { panda_cms_pages(:homepage) }
  let(:about_page) { panda_cms_pages(:about_page) }

  context "when not logged in" do
    it "returns a 404 error" do
      visit "/admin/pages/#{homepage.id}/edit"
      expect(page).to have_content("The page you were looking for doesn't exist.")
    end
  end

  context "when not logged in as an administrator" do
    it "returns a 404 error" do
      login_as_user
      visit "/admin/pages/#{homepage.id}/edit"
      expect(page).to have_content("The page you were looking for doesn't exist.")
    end
  end

  context "when logged in as an administrator" do
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
      end
    end

    it "updates the page details" do
      find("a", id: "slideover-toggle").click
      within("#slideover") do
        fill_in "Title", with: "Updated About Page"
        click_button "Save Page"
      end
      expect(page).to have_content("Updated About Page")
    end

    it "shows the correct link to the page" do
      expect(page).to have_link("Visit Page", href: "/about")
    end

    it "allows clicking the link to the page" do
      within_window(open_new_window) do
        visit "/about"
        expect(page).to have_content("About")
      end
    end

    it "shows the content of the page being edited" do
      expect(page).to have_content("About")
      expect(page).to have_content("Basic Page Layout")
    end

    it "allows editing plain text content of the page" do
      within_frame "editablePageFrame" do
        # Wait for the page to load
        expect(page).to have_content("Basic Page Layout")

        # Find and edit plain text content
        first_plain_text = find('span[data-editable-kind="plain_text"][contenteditable="plaintext-only"]', match: :first, wait: 10)

        # Clear existing content and add new content
        first_plain_text.click
        first_plain_text.send_keys([:control, "a"])
        first_plain_text.send_keys("Updated plain text content")

        # Move focus away to trigger save
        page.send_keys(:tab)

        # Give time for the save to process
        sleep 1

        # Verify the content was updated
        expect(first_plain_text.text).to eq("Updated plain text content")
      end

      # Refresh the page to verify persistence
      visit "/admin/pages/#{about_page.id}/edit"

      within_frame "editablePageFrame" do
        updated_text = find('span[data-editable-kind="plain_text"][contenteditable="plaintext-only"]', match: :first, wait: 10)
        expect(updated_text.text).to eq("Updated plain text content")
      end
    end

    it "allows editing rich text content of the page" do
      within_frame "editablePageFrame" do
        # Wait for the page to load
        expect(page).to have_content("Basic Page Layout")

        # Find the rich text editor area
        find('div[data-editable-kind="rich_text"]', wait: 10)

        # Wait for editor to be initialized
        wait_for_editor(about_page)

        # Add a header using the editor
        add_editor_header("Test Header", 2, about_page)

        # Add a paragraph
        add_editor_paragraph("This is a test paragraph with rich text content.", about_page)

        # Wait for content to be saved
        sleep 2

        # Verify content was added
        expect_editor_content_to_include("Test Header", about_page)
        expect_editor_content_to_include("This is a test paragraph with rich text content.", about_page)
      end

      # Refresh the page to verify persistence
      visit "/admin/pages/#{about_page.id}/edit"

      within_frame "editablePageFrame" do
        wait_for_editor(about_page)
        expect_editor_content_to_include("Test Header", about_page)
        expect_editor_content_to_include("This is a test paragraph with rich text content.", about_page)
      end
    end

    it "allows editing code content of the page" do
      within_frame "editablePageFrame" do
        # Wait for the page to load
        expect(page).to have_content("Basic Page Layout")

        # Find and edit HTML code content
        html_area = find('div[data-editable-kind="html"]', wait: 10)

        # Clear existing content and add new HTML
        html_area.click
        html_area.send_keys([:control, "a"])
        html_area.send_keys('<div class="updated-code"><h3>Updated HTML Content</h3><p>This is updated HTML code.</p></div>')

        # Move focus away to trigger save
        page.send_keys(:tab)

        # Give time for the save to process
        sleep 1

        # Verify the content was updated
        expect(html_area.text).to include("Updated HTML Content")
      end

      # Refresh the page to verify persistence
      visit "/admin/pages/#{about_page.id}/edit"

      within_frame "editablePageFrame" do
        updated_html = find('div[data-editable-kind="html"]', wait: 10)
        expect(updated_html.text).to include("Updated HTML Content")
      end
    end

    it "properly initializes Editor.js in the iframe context", :editorjs do
      within_frame "editablePageFrame" do
        # Find the rich text editor area
        find('div[data-editable-kind="rich_text"]', wait: 10)

        # Wait for editor to be initialized
        expect(wait_for_editor(about_page)).to be true

        # Verify that Editor.js is properly initialized
        editor_initialized = page.evaluate_script(<<~JS)
          (function() {
            try {
              return window.editor !== null &&
                     window.editor !== undefined &&
                     typeof window.editor.save === 'function';
            } catch (e) {
              return false;
            }
          })();
        JS

        expect(editor_initialized).to be true
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

        puts_debug "Editor.js resources status: #{resources_loaded}"

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
        # Initialize editor and add content
        wait_for_editor(about_page)

        # Add some content
        add_editor_paragraph("Initial content", about_page)

        # Verify content is there
        expect_editor_content_to_include("Initial content", about_page)

        # Simulate some page interactions (clicking around)
        find("h1").click
        find("h2").click

        # Verify editor state is maintained
        expect_editor_content_to_include("Initial content", about_page)

        # Add more content to verify editor is still functional
        add_editor_paragraph("Additional content", about_page)

        # Verify both pieces of content are present
        expect_editor_content_to_include("Initial content", about_page)
        expect_editor_content_to_include("Additional content", about_page)
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

        puts_debug "=== Editor Initialization Debug Info ==="
        puts_debug "Timestamp: #{debug_info["timestamp"]}"
        puts_debug "URL: #{debug_info["url"]}"
        puts_debug "Window Size: #{debug_info["windowSize"]["width"]}x#{debug_info["windowSize"]["height"]}"
        puts_debug "Global Editor Exists: #{debug_info["editor"]["global_exists"]}"
        puts_debug "EditorJS Class Exists: #{debug_info["editorjs"]["class_exists"]}"
        puts_debug "DOM Elements:"
        puts_debug "  - Editor Containers: #{debug_info["dom"]["editor_containers"]}"
        puts_debug "  - Editor Holders: #{debug_info["dom"]["editor_holders"]}"
        puts_debug "  - Editable Areas: #{debug_info["dom"]["editable_areas"]}"
        puts_debug "Components:"
        debug_info["components"].each do |name, status|
          puts_debug "  - #{name}: exists=#{status["exists"]}, type=#{status["type"]}"
        end
        if debug_info["errors"].any?
          puts_debug "Errors:"
          debug_info["errors"].each { |error| puts_debug "  - #{error}" }
        end
        puts_debug "========================================"

        # Basic assertions
        expect(debug_info["dom"]["editable_areas"]).to be > 0
        expect(debug_info["errors"]).to be_empty
      end
    end
  end
end
