module EditorHelpers
  def editor_container_id(record = nil)
    if record.is_a?(Panda::CMS::Page)
      'div[data-editable-kind="rich_text"]'
    else
      # For posts and other records, use dom_id pattern consistently
      record_for_dom = record || Panda::CMS::Post.new
      "#editor_#{ActionView::RecordIdentifier.dom_id(record_for_dom, :content)}"
    end
  end

  def wait_for_editor(record = nil)
    debug_editor_state(record)
    debug "Looking for editor container: #{editor_container_id(record)}"

    # Switch to iframe context if editing a page
    if record.is_a?(Panda::CMS::Page) && page.has_css?("#editablePageFrame", wait: 1)
      within_frame "editablePageFrame" do
        wait_for_editor_in_context(record)
      end
    else
      wait_for_editor_in_context(record)
    end
  end

  def wait_for_editor_in_context(record = nil)
    # First find the container
    container = find(editor_container_id(record), wait: 1)

    # Wait for editor to be initialized
    20.times do
      initialized = container["data-editor-initialized"]
      break if initialized == "true"
      sleep 0.1
    end

    # Verify editor is ready
    expect(page).to have_css(".codex-editor", wait: 1)
    expect(page).to have_css(".ce-toolbar", wait: 1)

    # Wait for editor instance to be available
    expect(page.evaluate_script('typeof window.editor !== "undefined" && window.editor !== null')).to be true

    # Ensure editor is ready for input
    expect(page).to have_css(".ce-block", wait: 1)
  end

  def wait_for_editor_initialization(record = nil)
    wait_for_editor(record)

    within(editor_container_id(record)) do
      # If editor is empty, we need to click it first
      if page.has_css?(".codex-editor--empty", wait: 1)
        find(".codex-editor--empty").click
      end
    end
  end

  def open_plus_menu
    # Click the last block first if any blocks exist
    if page.has_css?(".ce-block")
      all(".ce-block").last.click
    end

    # Open plus menu
    find(".ce-toolbar__plus").click
    expect(page).to have_css(".ce-popover--opened", wait: 1)
  end

  def add_editor_header(text, level = 1, record = nil)
    wait_for_editor_initialization(record)

    within(editor_container_id(record)) do
      # If editor is empty, we need to click it first
      if page.has_css?(".codex-editor--empty")
        find(".codex-editor--empty").click
      end

      # Open plus menu and select header
      open_plus_menu
      within(".ce-popover--opened") do
        find("[data-item-name='header']", wait: 5).click
      end

      # Wait for block to be created and find it
      header_block = find(".ce-block", wait: 10)

      # Change header level if needed
      if level > 1
        header_block.click
        find(".ce-inline-toolbar [data-level='#{level}']", wait: 5).click
      end

      # Add the header text using normal user input
      within(header_block) do
        input = find("[contenteditable]", wait: 10)
        input.click
        input.send_keys([:control, "a"], :backspace) # Clear any existing content
        input.send_keys(text)

        # Move focus away to ensure changes are saved
        input.send_keys(:tab)

        # Verify the text was entered
        expect(input.text).to eq(text)
      end
    end
  end

  def add_editor_paragraph(text, record = nil, replace_first: false)
    # Wait for editor to be ready
    debug_editor_state(record)
    debug "Looking for editor container: #{editor_container_id(record)}"

    within(editor_container_id(record)) do
      # Wait for editor to be initialized
      find(".codex-editor[data-editor-initialized='true']", wait: 10)

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

  def add_editor_list(items, type: :unordered, record: nil)
    wait_for_editor_initialization(record)

    within(editor_container_id(record)) do
      # Open plus menu and select list
      open_plus_menu
      within(".ce-popover--opened") do
        find("[data-item-name='list']", wait: 5).click
      end

      # Change list type if ordered
      if type == :ordered
        find(".ce-inline-toolbar__dropdown").click
        within(".ce-conversion-toolbar__tools") do
          find(".ce-conversion-tool[data-type='ordered']").click
        end
      end

      # Type each item directly
      items.each_with_index do |item, index|
        # Press enter before typing each item (except the first)
        page.send_keys(:enter) unless index == 0
        page.send_keys(item)
      end
    end
  end

  def add_editor_quote(text, caption = nil, record = nil)
    wait_for_editor_initialization(record)

    within(editor_container_id(record)) do
      # Store initial block count
      initial_blocks = all(".ce-block").count

      # Open plus menu and select quote
      open_plus_menu
      within(".ce-popover--opened") do
        find("[data-item-name='quote']", wait: 5).click
      end

      # Wait for new block to be created
      expect(page).to have_css(".ce-block", minimum: initial_blocks + 1)
      quote_block = all(".ce-block").last

      # Enter quote text
      within(quote_block) do
        inputs = all("[contenteditable]")
        quote_input = inputs.first
        quote_input.click
        quote_input.send_keys(text)

        if caption
          caption_input = inputs.last
          caption_input.click
          caption_input.send_keys(caption)
        end
      end

      # Move focus away to trigger save
      find(".ce-toolbar").click

      # Verify the quote was added
      expect(quote_block).to have_text(text)

      if ENV["DEBUG"]
        puts "\nChecking hidden field after adding quote:"
        if page.has_css?("[data-editor-form-target='hiddenField']", visible: false)
          hidden_field = find("[data-editor-form-target='hiddenField']", visible: false)
          puts "Hidden field value: #{hidden_field.value}"

          # Parse and pretty print the JSON for better readability
          begin
            json = JSON.parse(hidden_field.value)
            puts "\nParsed hidden field JSON:"
            puts JSON.pretty_generate(json)
          rescue JSON::ParserError => e
            puts "Error parsing JSON: #{e.message}"
          end
        else
          puts "Hidden field not found"
        end
      end
    end
  end

  def expect_editor_content_to_include(text, record = nil)
    within(editor_container_id(record)) do
      # Wait for editor to be ready
      editor = find(".codex-editor[data-editor-initialized='true']", wait: 10)

      # Look for the text in any editor block
      within(editor) do
        # Try finding in contenteditable first
        found = has_css?("[contenteditable]", text: text, wait: 5)

        # If not found in contenteditable, check the entire block content
        # This handles cases like quotes where text may be in a different structure
        unless found
          expect(page).to have_css(".ce-block", text: text, wait: 5)
        end
      end
    end
  end

  private

  def debug_editor_state(record = nil)
    return unless ENV["DEBUG"]
    debug "Current URL: #{current_url}"
    debug "Editor container ID we're looking for: #{editor_container_id(record)}"
    debug "Editor container present: #{page.has_css?("[data-controller='editor-form'] .codex-editor")}"
    debug "Hidden field present: #{page.has_css?("[data-editor-form-target='hiddenField']")}"
    debug "Block count: #{all(".ce-block").count}"

    # Debug all elements with ID containing 'editor'
    debug "All editor-related elements:"
    all("[id*='editor']").each do |el|
      debug "  Found element with ID: #{el["id"]}"
    end

    # Debug form elements
    debug "Form elements:"
    all("form").each do |form|
      debug "  Form action: #{form["action"]}"
      debug "  Form data controllers: #{form["data-controller"]}"
    end
  end

  def debug(message)
    puts message if ENV["DEBUG"]
  end
end

RSpec.configure do |config|
  config.include EditorHelpers, type: :system
end
