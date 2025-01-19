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

      # First ensure the iframe is loaded
      expect(page).to have_css("iframe#editablePageFrame")

      within_frame "editablePageFrame" do
        # Wait for the page content to be fully loaded
        expect(page).to have_content("About")
        expect(page).to have_content("Basic Page Layout")

        # Wait for editor initialization to complete and find the first plain text area
        first_plain_text = find('span[data-editable-kind="plain_text"][contenteditable="plaintext-only"]', match: :first, wait: 10)
        expect(first_plain_text["data-editable-kind"]).to eq("plain_text")

        # Debug: Print all editable elements
        puts_debug "Found editable elements:"
        all("[data-editable-kind]").each do |el|
          puts_debug "  - Kind: #{el["data-editable-kind"]}, Content: #{el.text}"
          puts_debug "  - HTML: #{el["outerHTML"]}"
        end

        # Set the content directly on the first plain text area
        first_plain_text.click
        first_plain_text.send_keys([:control, "a"], [:backspace])  # Clear existing content
        first_plain_text.send_keys("Here is some plain text content #{time}")
      end

      # Save the changes
      find("a", id: "saveEditableButton").click

      # Wait for the success message to be visible
      expect(page).to have_selector(".flash-message-text", text: /updated/i, visible: true, wait: 10)

      # Verify the changes
      visit "/about"
      expect(page).to have_content("Here is some plain text content #{time}")
    end

    it "allows editing rich text content of the page" do
      time = Time.now.strftime("%Y-%m-%d %H:%M:%S")

      # First ensure the iframe is loaded
      expect(page).to have_css("iframe#editablePageFrame")

      within_frame "editablePageFrame" do
        # Wait for rich text area to be present
        rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)
        rich_text_area.click

        # Wait for editor to initialize
        expect(page).to have_css(".codex-editor", wait: 10)
        expect(page).to have_css(".ce-block", wait: 10)
        expect(page).to have_css('.codex-editor.editor-ready, [data-editable-initialized="true"], [data-editor-initialized="true"]', wait: 10)

        # Find or create a paragraph block
        if page.has_css?(".ce-block")
          within(first(".ce-block")) do
            # Clear existing content
            find("[contenteditable]").click
            find("[contenteditable]").send_keys([:control, "a"], [:backspace])
            # Add new content
            find("[contenteditable]").set("New rich text content #{time}")
          end
        else
          # Click plus button to add a new block
          find(".ce-toolbar__plus").click
          within(".ce-popover--opened") do
            find("[data-item-name='paragraph']").click
          end
          # Add content to the new block
          within(first(".ce-block")) do
            find("[contenteditable]").set("New rich text content #{time}")
          end
        end

        # Verify content was added
        expect(page).to have_content("New rich text content #{time}", wait: 5)
      end

      # Click the save button
      find("a", id: "saveEditableButton").click

      # Wait for the success message
      expect(page).to have_selector(".flash-message-text", text: /updated/i, visible: true, wait: 10)

      # Verify the changes persisted
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
        html_area.send_keys([:control, "a"], [:backspace])  # Clear existing content
        html_area.send_keys("<h1>New code content #{time}</h1>")
        html_area.send_keys(:enter)
        html_area.send_keys("<p>Some paragraph from code block</p>")
      end

      # Click the save button
      find("a", id: "saveEditableButton").click

      # Wait for the success message to be visible
      expect(page).to have_selector(".flash-message-text", text: /updated/i, visible: true, wait: 10)

      # Visit the page and verify the rendered content
      visit "/about"
      expect(page).to have_content("New code content #{time}")
      expect(page).to have_content("Some paragraph from code block")
    end

    it "properly initializes Editor.js in the iframe context" do
      within_frame "editablePageFrame" do
        # Wait for rich text area to be present
        rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)

        # Debug output to help diagnose issues
        puts_debug "Rich text area attributes:"
        puts_debug rich_text_area["outerHTML"]

        # Verify the rich text area has required attributes
        expect(rich_text_area["data-editable-kind"]).to eq("rich_text")
        expect(rich_text_area["data-editable-block-content-id"]).to be_present
        expect(rich_text_area["data-editable-page-id"]).to be_present

        rich_text_area.click

        # Wait for editor to initialize
        expect(page).to have_css(".codex-editor", wait: 10)

        # Verify Editor.js is actually loaded in the iframe context
        editor_loaded = page.evaluate_script('typeof window.EditorJS === "function"')
        expect(editor_loaded).to be true

        # Verify editor instance is created
        editor_holder = page.evaluate_script('document.querySelector(".codex-editor")')
        expect(editor_holder).not_to be_nil

        # Verify toolbar is present and functional
        expect(page).to have_css(".ce-toolbar")
        expect(page).to have_css(".ce-toolbar__plus")

        # Try to interact with the editor
        rich_text_area.click
        rich_text_area.send_keys("Test content")
        expect(page).to have_content("Test content")

        # Verify editor data structure
        editor_data = page.evaluate_script('document.querySelector("[data-editable-kind=rich_text]").getAttribute("data-editable-previous-data")')
        decoded_data = JSON.parse(Base64.strict_decode64(editor_data))
        expect(decoded_data["version"]).to eq("2.28.2")
      end
    end

    it "loads all required Editor.js resources" do
      within_frame "editablePageFrame" do
        # Wait for rich text area and editor initialization
        rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)

        # Get all loaded scripts with detailed debug info
        scripts_info = page.evaluate_script(<<~JS)
          (function() {
            var loadedScripts = Array.prototype.slice.call(document.scripts).map(function(s) {
              return {
                src: s.src,
                type: s.type,
                async: s.async,
                defer: s.defer,
                loaded: s.loaded,
                error: s.error,
                text: s.text.substring(0, 100) // First 100 chars
              };
            });
            return loadedScripts;
          })();
        JS

        # Debug output of all scripts
        puts_debug "=== Loaded Scripts ==="
        scripts_info.each do |script|
          puts_debug "Script: #{script["src"]}"
          puts_debug "  Type: #{script["type"]}"
          puts_debug "  Async: #{script["async"]}"
          puts_debug "  Defer: #{script["defer"]}"
          puts_debug "  Loaded: #{script["loaded"]}"
          puts_debug "  Error: #{script["error"]}"
          puts_debug "  Text: #{script["text"]}"
          puts_debug "---"
        end

        # Verify required Editor.js scripts are loaded
        required_scripts = [
          "editorjs@2.28.2",
          "paragraph@2.11.3",
          "header@2.8.1",
          "nested-list@1.4.2",
          "quote@2.6.0",
          "simple-image@1.6.0",
          "table@2.3.0",
          "embed@2.7.0"
        ]

        scripts_loaded = page.evaluate_script(<<~JS)
          (function() {
            var scripts = Array.prototype.slice.call(document.scripts).map(function(s) {
              return s.src;
            });
            var required = #{required_scripts};
            var missing = [];
            var found = required.filter(function(script) {
              var isLoaded = scripts.some(function(s) {
                return s.indexOf(script) !== -1;
              });
              if (!isLoaded) {
                missing.push(script);
              }
              return isLoaded;
            });
            console.log('[Panda CMS Debug] Required scripts:', required);
            console.log('[Panda CMS Debug] Found scripts:', found);
            console.log('[Panda CMS Debug] Missing scripts:', missing);
            return {
              success: found.length === required.length,
              found: found,
              missing: missing
            };
          })();
        JS

        puts_debug "=== Script Loading Results ==="
        puts_debug "Found scripts: #{scripts_loaded["found"].join(", ")}"
        puts_debug "Missing scripts: #{scripts_loaded["missing"].join(", ")}"
        puts_debug "============================"

        if !scripts_loaded["success"]
          fail "Missing required Editor.js scripts: #{scripts_loaded["missing"].join(", ")}"
        end

        rich_text_area.click

        # Verify editor is functional after scripts load
        expect(page).to have_css(".codex-editor")
        expect(page).to have_css(".ce-toolbar")

        # Verify tools are actually initialized
        tools_initialized = page.evaluate_script(<<~JS)
          (function() {
            var editor = document.querySelector('.codex-editor');
            if (!editor) {
              console.log('[Panda CMS Debug] No editor element found');
              return false;
            }

            try {
              // Check for window.EDITOR_JS_TOOLS_INITIALIZED flag
              if (window.EDITOR_JS_TOOLS_INITIALIZED) {
                return true;
              }

              // Check for data attribute
              if (document.querySelector('[data-editor-tools-initialized="true"]')) {
                return true;
              }

              // Check for actual tool instances
              var requiredTools = ['Paragraph', 'Header', 'NestedList', 'Quote', 'SimpleImage', 'Table', 'Embed'];
              var missingTools = requiredTools.filter(function(tool) {
                return !window[tool];
              });

              console.log('[Panda CMS Debug] Editor tools check:', {
                hasToolsFlag: !!window.EDITOR_JS_TOOLS_INITIALIZED,
                hasDataAttribute: !!document.querySelector('[data-editor-tools-initialized="true"]'),
                missingTools: missingTools
              });

              return missingTools.length === 0;
            } catch (e) {
              console.log('[Panda CMS Debug] Error checking tools:', e);
              return false;
            }
          })();
        JS

        expect(tools_initialized).to be true
      end
    end

    it "handles Editor.js initialization failures gracefully" do
      within_frame "editablePageFrame" do
        # Wait for rich text area
        rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)
        rich_text_area.click

        # Debug: Print out what elements are available
        puts_debug "Available elements in iframe:"
        all("*").each do |element|
          puts_debug "  #{element.tag_name}: #{element["class"]}"
        end

        # Check for either successful initialization or error state
        expect(page).to have_css(".codex-editor", wait: 10)

        success = page.has_css?(".ce-toolbar", wait: 5)
        if !success
          # If toolbar isn't found, we should see an error message
          expect(page).to have_css(".editor-error-message")
          expect(page).to have_content("Editor failed to initialize")
        end
      end
    end

    it "maintains editor state after page interactions" do
      time = Time.now.strftime("%Y-%m-%d %H:%M:%S")

      # First ensure the iframe is loaded
      expect(page).to have_css("iframe#editablePageFrame")

      within_frame "editablePageFrame" do
        # Wait for rich text area and initialization
        rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)
        rich_text_area.click

        # Wait for editor to initialize
        expect(page).to have_css(".codex-editor", wait: 10)
        expect(page).to have_css(".ce-block", wait: 10)
        expect(page).to have_css('.codex-editor.editor-ready, [data-editable-initialized="true"], [data-editor-initialized="true"]', wait: 10)

        # Find or create a paragraph block
        if page.has_css?(".ce-block")
          within(first(".ce-block")) do
            find("[contenteditable]").click
            find("[contenteditable]").send_keys([:control, "a"], [:backspace])
            find("[contenteditable]").set("Test content #{time}")
          end
        else
          find(".ce-toolbar__plus").click
          within(".ce-popover--opened") do
            find("[data-item-name='paragraph']").click
          end
          within(first(".ce-block")) do
            find("[contenteditable]").set("Test content #{time}")
          end
        end

        # Verify content was added
        expect(page).to have_content("Test content #{time}")
      end

      # Trigger a page interaction by opening the slideover
      find("a", id: "slideover-toggle").click

      # Close the slideover using the Font Awesome X icon
      find("#slideover i.fa-xmark").click

      # Verify editor state is maintained
      within_frame "editablePageFrame" do
        expect(page).to have_content("Test content #{time}")
      end
    end

    it "outputs detailed editor initialization debug info" do
      within_frame "editablePageFrame" do
        # Wait for rich text area
        find('div[data-editable-kind="rich_text"]', wait: 10)

        # Output detailed initialization state
        editor_info = page.evaluate_script(<<~JS)
          (function() {
            const debugInfo = {
              // Window state
              windowState: {
                hasEditorJS: typeof window.EditorJS === 'function',
                hasEditorJSTools: Object.keys(window).filter(key => key.includes('Editor')),
                documentReadyState: document.readyState,
                hasContentEditable: !!document.querySelector('[contenteditable]'),
              },

              // Script loading state
              scripts: {
                all: Array.from(document.scripts).map(s => ({
                  src: s.src,
                  async: s.async,
                  defer: s.defer,
                  loaded: s.loaded,
                  error: s.error
                })),
                editorRelated: Array.from(document.scripts)
                  .filter(s => s.src.includes('editor'))
                  .map(s => s.src)
              },

              // Editor elements
              elements: {
                richTextAreas: Array.from(document.querySelectorAll('[data-editable-kind="rich_text"]'))
                  .map(el => ({
                    id: el.id,
                    attributes: Array.from(el.attributes).map(attr => ({
                      name: attr.name,
                      value: attr.value
                    })),
                    childNodes: el.childNodes.length,
                    innerHTML: el.innerHTML.substring(0, 100) + '...' // First 100 chars
                  })),
                editorElements: Array.from(document.querySelectorAll('.codex-editor, .ce-toolbar, .ce-block'))
                  .map(el => ({
                    className: el.className,
                    isVisible: window.getComputedStyle(el).display !== 'none',
                    dimensions: {
                      width: el.offsetWidth,
                      height: el.offsetHeight
                    }
                  }))
              },

              // Editor instance state
              editorState: (function() {
                const editorEl = document.querySelector('.codex-editor');
                if (!editorEl) return 'No editor element found';

                try {
                  return {
                    hasEditorInstance: '_editorJS' in editorEl,
                    toolbarVisible: !!document.querySelector('.ce-toolbar'),
                    availableTools: editorEl._editorJS ?
                      Object.keys(editorEl._editorJS.configuration.tools || {}) :
                      'No tools found',
                    blockCount: document.querySelectorAll('.ce-block').length,
                    hasUnsavedChanges: editorEl._editorJS ?
                      editorEl._editorJS.isChanged :
                      'Cannot determine'
                  };
                } catch (e) {
                  return `Error getting editor state: ${e.message}`;
                }
              })(),

              // Previous data
              previousData: (function() {
                const el = document.querySelector('[data-editable-previous-data]');
                if (!el) return 'No previous data found';
                try {
                  return JSON.parse(el.getAttribute('data-editable-previous-data'));
                } catch (e) {
                  return `Error parsing previous data: ${e.message}`;
                }
              })(),

              // Error state
              errors: (function() {
                const errors = [];
                if (!window.EditorJS) errors.push('EditorJS not loaded');
                if (!document.querySelector('.codex-editor')) errors.push('No editor element');
                if (!document.querySelector('.ce-toolbar')) errors.push('No toolbar');
                return errors;
              })()
            };

            console.log('[Panda CMS Debug] Editor Initialization State:', debugInfo);
            return debugInfo;
          })();
        JS

        # Output the debug info to the test log
        puts_debug "=== Editor Debug Information ==="
        puts_debug JSON.pretty_generate(editor_info)
        puts_debug "=============================="

        # Basic verification that we got debug info
        expect(editor_info["windowState"]).to be_present
        expect(editor_info["scripts"]).to be_present
        expect(editor_info["elements"]).to be_present

        # If there are errors, output them prominently
        if editor_info["errors"].any?
          puts_debug "!!! EDITOR INITIALIZATION ERRORS !!!"
          editor_info["errors"].each do |error|
            puts_debug "  - #{error}"
          end
        end
      end
    end

    xit "supports multiple Editor.js instances on the same page" do
      within_frame "editablePageFrame" do
        # Wait for initial editor to be present
        rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)
        rich_text_area.click

        # Wait for editor to initialize
        expect(page).to have_css(".codex-editor", wait: 10)
        expect(page).to have_css(".ce-toolbar__plus", wait: 10)
        expect(page).to have_css('.codex-editor.editor-ready, [data-editable-initialized="true"], [data-editor-initialized="true"]', wait: 10)

        # Debug output before starting
        puts_debug "=== Initial Editor Blocks ==="
        all(".ce-block").each_with_index do |block, index|
          puts_debug "Block #{index + 1}: #{block.text}"
        end

        # Clear all blocks by selecting all and deleting
        first(".ce-block").click
        find("[contenteditable]").send_keys([:control, "a"], [:backspace])
        expect(page).not_to have_content("This is the main content of the about page")

        # Add content to first block
        within(first(".ce-block")) do
          input = find("[contenteditable]")
          input.click
          input.set("Content for editor 1")
        end

        # Verify first block content
        expect(page).to have_content("Content for editor 1", wait: 5)

        # Add two more blocks
        2.times do |i|
          puts_debug "=== Starting iteration #{i + 1} ==="

          # Click plus button to add a new block
          find(".ce-toolbar__plus").click
          expect(page).to have_css(".ce-popover--opened", wait: 5)

          within(".ce-popover--opened") do
            find("[data-item-name='paragraph']").click
          end

          # Wait for the new block to be created and become interactive
          expect(page).to have_css(".ce-block", minimum: i + 2, wait: 5)
          sleep 1 # Give the editor more time to fully create and stabilize the block

          # Find all blocks and verify we have the expected number
          blocks = all(".ce-block")
          expect(blocks.length).to be >= (i + 2)

          # Get the target block and ensure it's the one we want
          target_block = blocks[i + 1]
          expect(target_block).to be_present

          # Click the block first to ensure it's focused
          target_block.click
          sleep 0.5 # Give the editor time to handle the focus

          # Now find the contenteditable within the focused block
          within(target_block) do
            # Wait for the contenteditable to be present and visible
            input = find("[contenteditable]", wait: 5)
            expect(input).to be_visible

            # Try to focus and interact with the input
            input.click
            sleep 0.5 # Give the editor time to handle the click

            # Set new content
            input.set("Content for editor #{i + 2}")
          end

          # Verify the content was added
          expect(page).to have_content("Content for editor #{i + 2}", wait: 5)

          # Debug output after this iteration
          puts_debug "=== After iteration #{i + 1} ==="
          all(".ce-block").each_with_index do |block, index|
            puts_debug "Block #{index + 1}: #{block.text}"
          end
        end

        # Final verification
        expect(page).to have_content("Content for editor 1")
        expect(page).to have_content("Content for editor 2")
        expect(page).to have_content("Content for editor 3")

        # Final debug output
        puts_debug "=== Final Editor Blocks ==="
        all(".ce-block").each_with_index do |block, index|
          puts_debug "Block #{index + 1}: #{block.text}"
        end
        puts_debug "===================="
      end
    end
  end
end
