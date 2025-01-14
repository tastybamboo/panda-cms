module EditorHelpers
  def editor_container_id(post = nil)
    if post&.persisted?
      "#editor_post_#{post.id}_content"
    else
      "#editor_post_content"
    end
  end

  def wait_for_editor(post = nil)
    debug_editor_state
    within(editor_container_id(post)) do
      # Wait for editor to be fully initialized
      find(".codex-editor[data-editor-initialized='true']", wait: 10)
      find(".ce-toolbar__plus", wait: 5)
      # Only click if empty
      if page.has_css?(".codex-editor--empty", wait: 1)
        find(".codex-editor--empty").trigger("click")
      end
    end
  end

  def add_editor_header(text, level = 1)
    wait_for_editor_initialization
    find(".ce-toolbar__plus").click
    find("[data-item-name='header']", wait: 1).click
    if level > 1
      find(".ce-inline-toolbar [data-level='#{level}']").click
    end
    find(".ce-paragraph").send_keys(text)
  end

  def open_plus_menu
    if page.has_css?(".ce-toolbar__plus")
      find(".ce-toolbar__plus").click
    else
      # If plus button isn't visible, click at the end of the last block to show it
      last_block = all(".ce-block").last
      last_block.click
      find(".ce-toolbar__plus").click
    end
  end

  def add_editor_paragraph(text, post = nil, replace_first: false)
    # Wait for editor to be ready
    debug_editor_state
    debug "Looking for editor container: #{editor_container_id(post)}"

    within(editor_container_id(post)) do
      # Find the inner editor instance
      editor = find(".codex-editor--empty", wait: 1)

      if replace_first && page.has_css?(".ce-block")
        # Click the first paragraph to focus it
        first_block = find(".ce-block")
        first_block.click
        # Clear existing content
        first_block.find("[contenteditable]").send_keys([:control, "a"], :backspace)
        # Enter new content
        first_block.find("[contenteditable]").set(text)
      else
        # Open the plus menu if we're adding a new block
        unless page.has_css?(".ce-block") && find_all(".ce-block").count == 1 && find(".ce-block [contenteditable]").text.blank?
          open_plus_menu
          within(".ce-popover--opened") do
            find("[data-item-name='paragraph']").click
          end
        end

        # Find the last block and enter text
        within(all(".ce-block").last) do
          find("[contenteditable]").set(text)
        end
      end
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
      items[1..].each do |item|
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

  def expect_editor_content_to_include(text)
    # Wait for editor to be ready
    find(".codex-editor")

    # Check if any block contains the text
    expect(page).to have_css(".ce-block [contenteditable]", text: text)
  end

  def wait_for_editor_initialization
    find(".codex-editor[data-editor-initialized='true']", wait: 10)
    find(".ce-toolbar__plus", wait: 5)
  end

  private

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
