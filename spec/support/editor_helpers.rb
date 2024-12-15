module EditorHelpers
  def add_editor_header(text, level: 2)
    debug "Adding editor header: #{text} (level #{level})"
    prepare_for_new_element

    # Find and click the header option in the tools menu
    within_editor do
      within(".ce-popover__items") do
        find("[data-item-name='header']").click
      end
    end
    debug "Selected header tool"

    # Type the header text
    within_editor do
      header_element = find("h#{level}.ce-header[contenteditable='true']")
      header_element.send_keys(text)
    end
    debug "Entered header text: #{text}"

    # Change header level if needed (default is h2)
    if level != 2
      debug "Changing header level to #{level}"
      within_editor do
        # Click the dropdown to show header levels
        find(".ce-inline-toolbar__dropdown").click

        # Select the desired header level
        within(".ce-conversion-toolbar__tools") do
          find(".ce-conversion-tool[data-level='#{level}']").click
        end
      end
      debug "Changed to h#{level}"
    end
  end

  def add_editor_list(items, type: :unordered)
    debug "Adding editor list: #{items.inspect} (type: #{type})"
    prepare_for_new_element

    # Find and click the list option in the tools menu
    within_editor do
      within(".ce-popover__items") do
        find("[data-item-name='list']").click
      end
    end
    debug "Selected list tool"

    # Change list type if ordered
    if type == :ordered
      debug "Changing to ordered list"
      within_editor do
        find(".ce-inline-toolbar__dropdown").click
        within(".ce-conversion-toolbar__tools") do
          find(".ce-conversion-tool[data-type='ordered']").click
        end
      end
    end

    # Add each item
    within_editor do
      items.each_with_index do |item, index|
        debug "Adding list item #{index + 1}: #{item}"
        if index > 0
          find(".ce-block--focused").send_keys(:enter)
        end
        find(".cdx-block[contenteditable='true']").send_keys(item)
      end
    end
  end

  private

  def prepare_for_new_element
    debug_editor_state

    within_editor do
      # Find the active redactor
      within(".codex-editor__redactor") do
        if page.has_css?(".ce-paragraph[data-placeholder='Enter some text']", wait: 0)
          debug "Initial empty editor state detected"
          find(".ce-paragraph[data-placeholder='Enter some text']").click
        else
          debug "Editor already has content"
          last_block = all(".ce-block").last
          last_block.click
          debug "Clicked last block, plus button should be visible"
        end
      end

      # The plus button is in the toolbar, outside the redactor
      find(".ce-toolbar__plus", wait: 5).click
    end
    debug "Clicked plus button"
  end

  def within_editor
    # Wait for editor to be ready
    container = find("[data-editor-form-target='editorContainer']")
    holder_id = container[:id] + "_holder"

    debug "Looking for editor in holder: #{holder_id}"

    # Wait for the editor to be initialized
    page.has_css?("##{holder_id} .codex-editor", wait: 10)

    # Find the active editor instance
    within("##{holder_id} .codex-editor") do
      yield
    end
  end

  def debug_editor_state
    return unless ENV["DEBUG"]

    debug "\n=== Editor State ==="
    # Get available tools
    tools = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('.ce-popover-item'))
        .map(el => el.dataset.itemName)
    JS
    debug "Available tools: #{tools.inspect}"

    # Get editor structure
    structure = page.evaluate_script(<<~JS)
      {
        blocks: window.editor?.blocks?.getBlocksCount() || 0,
        isEmpty: window.editor?.isEmpty,
        tools: Object.keys(window.editor?.configuration?.tools || {})
      }
    JS
    debug "Editor structure: #{structure.inspect}"
    debug "=== End Editor State ==="
  end

  def debug(message)
    puts message if ENV["DEBUG"]
  end
end
