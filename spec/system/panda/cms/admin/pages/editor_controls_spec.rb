require "system_helper"

RSpec.describe "When using the Editor.js controls", type: :system do
  include EditorHelpers
  include_context "with standard pages"

  let(:about_page) { Panda::CMS::Page.find_by(path: "/about") }

  before(:each) do
    login_as_admin
    visit "/admin/pages/#{about_page.id}/edit"
  end

  it "loads previous content from data-editable-previous-data attribute" do
    within_frame "editablePageFrame" do
      # Wait for editor initialization
      wait_for_editor

      # Set up the test data
      previous_data = {
        time: 1736094153000,
        blocks: [
          {type: "paragraph", data: {text: "Testing."}},
          {type: "paragraph", data: {text: "Testing."}},
          {type: "list", data: {
            style: "unordered",
            items: [
              {content: "<b>12345.</b>", items: []},
              {content: "Testing.", items: []},
              {content: "Testing.", items: []}
            ]
          }},
          {type: "paragraph", data: {text: "Testing 1234."}}
        ],
        version: "2.28.2"
      }

      # Set the previous data
      editor_container = find('div[data-editable-kind="rich_text"]')
      page.execute_script(
        "arguments[0].dataset.editablePreviousData = '#{Base64.strict_encode64(previous_data.to_json)}'",
        editor_container
      )

      # Reload the editor
      page.execute_script("window.location.reload()")

      # Wait for editor to reinitialize
      wait_for_editor

      # Verify content is loaded
      expect(page).to have_content("Testing.")
      expect(page).to have_content("12345.")
      expect(page).to have_content("Testing 1234.")
    end
  end

  xit "allows rich text formatting with keyboard shortcuts" do
    within_frame "editablePageFrame" do
      rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)
      rich_text_area.click

      # Wait for editor to initialize
      expect(page).to have_css(".codex-editor", wait: 10)
      expect(page).to have_css(".ce-block", wait: 10)

      # Debug: Print out what elements are available
      debug "Available elements:"
      debug page.all(".codex-editor *").map(&:tag_name).join(", ")

      # Clear and type new text
      rich_text_area.send_keys([:control, "a"], [:backspace])
      rich_text_area.send_keys("This is some text")

      # Select text using keyboard shortcuts
      rich_text_area.send_keys([:control, "a"])

      # Use keyboard shortcut for bold
      rich_text_area.send_keys([:control, "b"])
    end

    find("a", id: "saveEditableButton").click
    expect(page).to have_selector(".flash-message-text", text: /updated/i, visible: true, wait: 10)

    visit "/about"
    expect(page).to have_content("This is some text")
  end

  xit "allows creating lists" do
    within_frame "editablePageFrame" do
      rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)
      rich_text_area.click

      # Wait for editor to initialize
      expect(page).to have_css(".codex-editor", wait: 10)
      expect(page).to have_css(".ce-block", wait: 10)

      # Debug: Print out what elements are available
      debug "Available elements:"
      debug page.all(".codex-editor *").map(&:tag_name).join(", ")

      # Create unordered list
      find(".ce-toolbar__plus", wait: 10).click
      find('.ce-popover-item[data-item-name="list"]', wait: 10).click
      rich_text_area.send_keys("First bullet")
      rich_text_area.send_keys(:enter)
      rich_text_area.send_keys("Second bullet")
      rich_text_area.send_keys(:enter, :enter)

      # Create ordered list
      find(".ce-toolbar__plus", wait: 10).click
      find('.ce-popover-item[data-item-name="list"]', wait: 10).click
      find('.ce-inline-toolbar [data-type="ordered"]', wait: 10).click
      rich_text_area.send_keys("First numbered")
      rich_text_area.send_keys(:enter)
      rich_text_area.send_keys("Second numbered")
    end

    find("a", id: "saveEditableButton").click
    expect(page).to have_selector(".flash-message-text", text: /updated/i, visible: true, wait: 10)

    visit "/about"
    expect(page).to have_content("First bullet")
    expect(page).to have_content("Second bullet")
    expect(page).to have_content("First numbered")
    expect(page).to have_content("Second numbered")
  end

  xit "creates headers using toolbar" do
    within_frame "editablePageFrame" do
      rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)
      rich_text_area.click

      # Wait for editor to initialize and toolbar to be rendered
      expect(page).to have_css(".ce-toolbar", wait: 10)
      expect(page).to have_css(".ce-block", wait: 10)  # Wait for block wrapper
      sleep 1  # Give time for toolbar to fully render

      rich_text_area.send_keys([:control, "a"], [:backspace])

      # Create H1
      find(".ce-toolbar__plus").click
      expect(page).to have_css(".ce-popover--opened", wait: 10)
      find('.ce-popover-item[data-item-name="header"]').click
      rich_text_area.send_keys("Heading 1")
      rich_text_area.send_keys(:enter)

      # Create H2
      find(".ce-toolbar__plus").click
      expect(page).to have_css(".ce-popover--opened", wait: 10)
      find('.ce-popover-item[data-item-name="header"]').click
      find('.ce-inline-toolbar [data-level="2"]').click
      rich_text_area.send_keys("Heading 2")
      rich_text_area.send_keys(:enter)

      # Create H3
      find(".ce-toolbar__plus").click
      expect(page).to have_css(".ce-popover--opened", wait: 10)
      find('.ce-popover-item[data-item-name="header"]').click
      find('.ce-inline-toolbar [data-level="3"]').click
      rich_text_area.send_keys("Heading 3")
    end

    find("a", id: "saveEditableButton").click
    expect(page).to have_selector(".flash-message-text", text: /updated/i, visible: true, wait: 10)

    visit "/about"
    expect(page).to have_content("Heading 1")
    expect(page).to have_content("Heading 2")
    expect(page).to have_content("Heading 3")
  end

  xit "creates and edits tables using toolbar" do
    within_frame "editablePageFrame" do
      rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)
      rich_text_area.click

      # Wait for editor to initialize and toolbar to be rendered
      expect(page).to have_css(".ce-toolbar", wait: 10)
      expect(page).to have_css(".ce-block", wait: 10)  # Wait for block wrapper
      sleep 1  # Give time for toolbar to fully render

      rich_text_area.send_keys([:control, "a"], [:backspace])

      # Create table
      find(".ce-toolbar__plus").click
      expect(page).to have_css(".ce-popover--opened", wait: 10)
      find('.ce-popover-item[data-item-name="table"]').click

      # Wait for table to be created and fill cells
      expect(page).to have_css(".tc-table", wait: 10)
      all(".tc-table td").each_with_index do |cell, index|
        cell.click
        cell.send_keys("Cell #{index + 1}")
      end
    end

    find("a", id: "saveEditableButton").click
    expect(page).to have_selector(".flash-message-text", text: /updated/i, visible: true, wait: 10)

    visit "/about"
    expect(page).to have_content("Cell 1")
    expect(page).to have_content("Cell 2")
  end

  xit "embeds images using toolbar" do
    within_frame "editablePageFrame" do
      rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)
      rich_text_area.click

      # Wait for editor to initialize and toolbar to be rendered
      expect(page).to have_css(".ce-toolbar", wait: 10)
      expect(page).to have_css(".ce-block", wait: 10)  # Wait for block wrapper
      sleep 0.5  # Give time for toolbar to fully render

      rich_text_area.send_keys([:control, "a"], [:backspace])

      # Wait for plus button and click
      find(".ce-toolbar__plus").click

      # Wait for tools menu and select image
      expect(page).to have_css(".ce-popover", wait: 10)
      find('.ce-popover-item[data-item-name="image"]').click

      # Wait for image block and input URL
      expect(page).to have_css(".ce-block--selected .cdx-input", wait: 10)
      find(".ce-block--selected .cdx-input").set("https://via.placeholder.com/150")
      rich_text_area.send_keys(:enter)
      rich_text_area.send_keys("Image caption")
    end

    find("a", id: "saveEditableButton").click
    expect(page).to have_selector(".flash-message-text", text: /updated/i, visible: true, wait: 10)

    visit "/about"
    expect(page).to have_selector('img[src*="placeholder"]')
    expect(page).to have_content("Image caption")
  end

  xit "supports undo/redo functionality" do
    within_frame "editablePageFrame" do
      rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)
      rich_text_area.click

      # Wait for editor to initialize and toolbar to be rendered
      expect(page).to have_css(".ce-toolbar", wait: 10)
      expect(page).to have_css(".ce-block", wait: 10)  # Wait for block wrapper
      sleep 1  # Give time for toolbar to fully render

      rich_text_area.send_keys([:control, "a"], [:backspace])

      # Type initial content
      rich_text_area.send_keys("Initial text")
      expect(page).to have_content("Initial text")

      # Use undo/redo buttons
      find('.ce-toolbar [data-tool="undo"]').click
      sleep 0.5  # Give time for undo to take effect
      expect(page).not_to have_content("Initial text")

      find('.ce-toolbar [data-tool="redo"]').click
      sleep 0.5  # Give time for redo to take effect
      expect(page).to have_content("Initial text")
    end

    find("a", id: "saveEditableButton").click
    expect(page).to have_selector(".flash-message-text", text: /updated/i, visible: true, wait: 10)

    visit "/about"
    expect(page).to have_content("Initial text")
  end

  xit "supports copy/paste functionality" do
    within_frame "editablePageFrame" do
      rich_text_area = find('div[data-editable-kind="rich_text"]', wait: 10)
      rich_text_area.click
      rich_text_area.send_keys([:control, "a"], [:backspace])

      # Type and format some text
      rich_text_area.send_keys("Text block one")
      rich_text_area.send_keys(:enter, :enter)
      rich_text_area.send_keys("Text block two")
    end

    find("a", id: "saveEditableButton").click
    expect(page).to have_selector(".flash-message-text", text: /updated/i, visible: true, wait: 10)

    visit "/about"
    expect(page).to have_content("Text block one")
    expect(page).to have_content("Text block two")
  end
end
