module EditorHelpers
  def wait_for_editor
    expect(page).to have_css("[data-controller='editor-form'] .codex-editor")
  end

  def add_editor_header(text, level: 2)
    open_plus_menu
    within(".ce-popover--opened") do
      find("[data-item-name='header']").click
    end

    # Type the header text in the most recently added block
    within(all(".ce-block").last) do
      header_input = find("h#{level}.ce-header[contenteditable='true']")
      header_input.set(text)
    end

    # Change header level if needed (default is h2)
    if level != 2
      find(".ce-inline-toolbar__dropdown").click
      within(".ce-conversion-toolbar__tools") do
        find(".ce-conversion-tool[data-level='#{level}']").click
      end
    end
  end

  def add_editor_paragraph(text)
    open_plus_menu
    within(".ce-popover--opened") do
      find("[data-item-name='paragraph']").click
    end

    # Type the paragraph text in the most recently added block
    within(all(".ce-block").last) do
      paragraph_input = find(".ce-paragraph[contenteditable='true']")
      paragraph_input.set(text)
    end
  end

  def add_editor_list(items, type: :unordered)
    open_plus_menu
    within(".ce-popover--opened") do
      find("[data-item-name='list']").click
    end

    # Change list type if ordered
    if type == :ordered
      find(".ce-inline-toolbar__dropdown").click
      within(".ce-conversion-toolbar__tools") do
        find(".ce-conversion-tool[data-type='ordered']").click
      end
    end

    # Add each item in the most recently added block
    within(all(".ce-block").last) do
      # Find the list container
      list_container = find(".cdx-nested-list")

      # Add first item
      first_item = list_container.find(".cdx-nested-list__item [contenteditable='true']")
      first_item.set(items.first)

      # Add remaining items
      items[1..-1].each do |item|
        first_item.send_keys(:enter)
        # Wait for the new list item and find it
        list_items = list_container.all(".cdx-nested-list__item [contenteditable='true']")
        new_item = list_items.last
        new_item.set(item)
      end
    end
  end

  def add_editor_quote(text, caption)
    open_plus_menu
    within(".ce-popover--opened") do
      find("[data-item-name='quote']").click
    end

    # Add quote text and caption in the most recently added block
    within(all(".ce-block").last) do
      quote_input = find(".cdx-quote__text[contenteditable='true']")
      quote_input.set(text)

      caption_input = find(".cdx-quote__caption[contenteditable='true']")
      caption_input.set(caption)
    end
  end

  private

  def open_plus_menu
    # Find and click the last block
    blocks = all(".ce-block")
    if blocks.any?
      blocks.last.click
    else
      # If no blocks exist, click the empty editor area
      find(".codex-editor__redactor").click
    end

    # Click the plus button to open the menu
    find(".ce-toolbar__plus").click
    expect(page).to have_css(".ce-popover--opened")
  end

  def debug_editor_state
    return unless ENV["DEBUG"]
    debug "Editor container present: #{page.has_css?("[data-controller='editor-form'] .codex-editor")}"
    debug "Hidden field present: #{page.has_css?("[data-editor-form-target='hiddenField']")}"
    debug "Block count: #{all(".ce-block").count}"
  end

  def debug(message)
    puts message if ENV["DEBUG"]
  end
end

RSpec.configure do |config|
  config.include EditorHelpers, type: :system
end
