module EditorHelpers
  def wait_for_editor
    find(".codex-editor", wait: 1).trigger("click")
  end

  def add_editor_header(text, level = 2)
    open_plus_menu
    within(".ce-popover--opened", wait: 1) do
      find("[data-item-name='header']", wait: 1).click
    end

    within(all(".ce-block").last, wait: 1) do
      find(".ce-header[contenteditable='true']", wait: 1).set(text)
    end
  end

  def open_plus_menu
    find(".ce-toolbar__plus", wait: 1).click
    expect(page).to have_css(".ce-popover--opened", wait: 1)
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
      # Need to add text first so the dropdown menu will show
      # within(all(".ce-block").last) do
      #   first_item = find(".cdx-nested-list__item [contenteditable='true']")
      #   first_item.set("temp")
      # end

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


  def add_editor_quote(text, caption = nil)
    open_plus_menu
    within(".ce-popover--opened") do
      find("[data-item-name='quote']").click
    end

    within(all(".ce-block").last) do
      quote_input = find(".cdx-quote__text[contenteditable='true']")
      quote_input.set(text)

      if caption
        caption_input = find(".cdx-quote__caption[contenteditable='true']")
        caption_input.set(caption)
      end
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
