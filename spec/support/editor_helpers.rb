module EditorHelpers
  def editor_container_id(record = nil)
    if record.is_a?(Panda::CMS::Page)
      'div[data-editable-kind="rich_text"]'
    elsif record.nil?
      'div[data-editor-form-target="editorContainer"]'
    else
      # For posts and other records, use dom_id pattern consistently
      record_for_dom = record || Panda::CMS::Post.new
      "#editor_#{ActionView::RecordIdentifier.dom_id(record_for_dom, :content)}"
    end
  end

  def wait_for_editor_resources
    # Wait for EditorJS core
    result = page.evaluate_script(<<~JS)
      (function() {
        try {
          const win = window;
          console.debug('[Panda CMS] Checking EditorJS resources:');
          const resources = {
            editorJS: !!win.EditorJS,
            paragraph: !!win.Paragraph,
            header: !!win.Header,
            nestedList: !!win.NestedList,
            quote: !!win.Quote,
            table: !!win.Table
          };

          // List all available tools in window
          const tools = Object.keys(win).filter(key =>
            key.includes('Editor') ||
            key.includes('Paragraph') ||
            key.includes('Header') ||
            key.includes('List') ||
            key.includes('Quote') ||
            key.includes('Table')
          );

          // List all loaded scripts
          const scripts = Array.from(document.scripts).map(s => s.src);

          // Log everything to console for debugging
          console.debug('Resources:', resources);
          console.debug('Available tools:', tools);
          console.debug('Loaded scripts:', scripts);

          // Return the results
          return {
            success: !!(
              win.EditorJS &&
              win.Paragraph &&
              win.Header &&
              win.NestedList &&
              win.Quote &&
              win.Table
            ),
            resources,
            tools,
            scripts
          };
        } catch (e) {
          console.error('Error checking resources:', e);
          return { success: false, error: e.message };
        }
      })();
    JS

    # Log the results to puts_debug
    if ENV["DEBUG"]
      puts_debug "[Panda CMS] EditorJS Resources Check:"
      puts_debug "  - EditorJS: #{result["resources"]["editorJS"]}"
      puts_debug "  - Paragraph: #{result["resources"]["paragraph"]}"
      puts_debug "  - Header: #{result["resources"]["header"]}"
      puts_debug "  - NestedList: #{result["resources"]["nestedList"]}"
      puts_debug "  - Quote: #{result["resources"]["quote"]}"
      puts_debug "  - Table: #{result["resources"]["table"]}"
      puts_debug "Available tools: #{result["tools"].join(", ")}"
      puts_debug "Loaded scripts: #{result["scripts"].join(", ")}"
    end

    result["success"]
  end

  def wait_for_editor(record = nil)
    @editor_container_id = editor_container_id(record)
    puts_debug "Looking for editor container: #{@editor_container_id}"

    # First ensure all editor resources are loaded
    wait_for_editor_resources

    # Switch to iframe context if editing a page
    if record.is_a?(Panda::CMS::Page) && page.has_css?("#editablePageFrame", wait: 5)
      within_frame "editablePageFrame" do
        wait_for_editor_in_context(page)
      end
    else
      wait_for_editor_in_context(page)
    end
  end

  def wait_for_editor_in_context(context)
    # First find the editor container
    editor_container = if @editor_container_id.start_with?("#")
      context.find("##{@editor_container_id.sub("#", "")}")
    else
      context.find(@editor_container_id)
    end
    puts_debug "Editor container present: #{editor_container.present?}"

    # Check for hidden field
    hidden_field = context.find("input[data-editor-form-target='hiddenField']", visible: false)
    puts_debug "Hidden field present: #{hidden_field.present?}"

    # Get block count
    block_count = context.evaluate_script("document.querySelectorAll('.ce-block').length")
    puts_debug "Block count: #{block_count}"

    # Check if editor exists
    editor_exists = context.evaluate_script("window.editor !== null && window.editor !== undefined")
    puts_debug "Editor instance check:"
    puts_debug "  Global editor exists: #{editor_exists}"

    # If not found, try finding it on the holder element within the container
    unless editor_exists
      begin
        # Scope the search to the editor container
        editor_holder = editor_container.find(".codex-editor", match: :first)
        editor_exists = context.evaluate_script("arguments[0].editorInstance !== null", editor_holder)
        puts_debug "  Editor holder found and has instance: #{editor_exists}"
      rescue Capybara::ElementNotFound
        puts_debug "  No editor holder found"
      end
    end

    # Debug output for all editor-related elements
    puts_debug "All editor-related elements:"
    editor_container.all("[id*='editor']").each do |el|
      puts_debug "  Found element with ID: #{el["id"]}"
    end

    # Debug output for form elements
    puts_debug "Form elements:"
    context.all("form").each do |form|
      puts_debug "  Form action: #{form["action"]}"
      puts_debug "  Form data controllers: #{form["data-controller"]}"
    end

    editor_exists
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
    puts_debug "Looking for editor container: #{editor_container_id(record)}"

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
    initial_block_count = count_editor_blocks
    puts_debug "Initial block count: #{initial_block_count}"

    # Click the plus button to open the tools menu
    find(".ce-toolbar__plus").click
    puts_debug "Clicked plus button"

    # Wait for and click the quote tool
    find("[data-item-name='quote']").click
    puts_debug "Clicked quote tool"

    # Wait for the new block to be created
    wait_until_block_count_increases(initial_block_count)
    puts_debug "Block count increased"

    # Wait for the quote block and its elements to be fully initialized
    quote_block = find(".cdx-quote", wait: 10)
    puts_debug "Found quote block"

    # Wait for the editor to be ready after adding the block
    # Try multiple ways to ensure the block is focused and ready
    begin
      Timeout.timeout(10) do
        until page.has_css?(".ce-block--focused") || quote_block.matches_css?(".ce-block--focused", wait: 0)
          begin
            quote_block.click
          rescue
            nil
          end
          sleep 0.1
        end
      end
    rescue Timeout::Error
      puts_debug "Warning: Could not find focused block, continuing anyway"
    end
    puts_debug "Editor focused on new block"

    # Wait for the text input to be ready and click it
    quote_input = quote_block.find(".cdx-quote__text", wait: 10)
    puts_debug "Found quote input"

    # Try multiple times to focus and enter text
    3.times do |i|
      quote_input.click
      puts_debug "Clicked quote input attempt #{i + 1}"

      # Clear any existing content and enter the new text
      quote_input.send_keys([:control, "a"], :backspace) if quote_input.text.present?
      quote_input.send_keys(text)
      puts_debug "Entered quote text: #{text}"

      # Verify the text was entered
      break if quote_input.text == text
    rescue Capybara::ElementNotFound => e
      puts_debug "Failed to enter text attempt #{i + 1}: #{e.message}"
      sleep 0.5
    end

    if caption
      # Wait for the caption input to be ready and click it
      caption_input = quote_block.find(".cdx-quote__caption", wait: 10)
      puts_debug "Found caption input"

      3.times do |i|
        caption_input.click
        puts_debug "Clicked caption input attempt #{i + 1}"

        # Clear any existing content and enter the new caption
        caption_input.send_keys([:control, "a"], :backspace) if caption_input.text.present?
        caption_input.send_keys(caption)
        puts_debug "Entered caption text: #{caption}"

        # Verify the caption was entered
        break if caption_input.text == caption
      rescue Capybara::ElementNotFound => e
        puts_debug "Failed to enter caption attempt #{i + 1}: #{e.message}"
        sleep 0.5
      end
    end

    # Move focus away to ensure changes are saved
    page.send_keys(:tab)
    puts_debug "Moved focus away from quote block"

    # Wait a moment for changes to be saved
    sleep 0.5

    # Verify the content was entered correctly
    expect(quote_block.find(".cdx-quote__text").text).to eq(text)
    puts_debug "Verified quote text: #{text}"
    if caption
      expect(quote_block.find(".cdx-quote__caption").text).to eq(caption)
      puts_debug "Verified caption text: #{caption}"
    end
  end

  def expect_editor_content_to_include(text, record = nil)
    wait_for_editor_initialization(record)

    # Wait for blocks to be rendered
    expect(page).to have_css(".ce-block")

    # Get all blocks
    blocks = all(".ce-block")

    # Debug output
    puts_debug "=== Editor Blocks ==="
    blocks.each_with_index do |block, index|
      puts_debug "Block #{index + 1}:"
      puts_debug "  Text: #{block.text}"
      puts_debug "  Classes: #{block["class"]}"

      # Get the block content based on its type
      content_html = if block.has_css?(".cdx-quote")
        quote_block = block.find(".cdx-quote")
        text_html = quote_block.find(".cdx-quote__text").text
        caption_html = quote_block.has_css?(".cdx-quote__caption") ? "\n#{quote_block.find(".cdx-quote__caption").text}" : ""
        text_html + caption_html
      else
        block.find(".ce-block__content").text
      end

      puts_debug "  Content: #{content_html}"
    end
    puts_debug "===================="

    # Check if text is found in any block
    found = blocks.any? do |block|
      if block.has_css?(".cdx-quote")
        quote_block = block.find(".cdx-quote")
        quote_text = quote_block.find(".cdx-quote__text").text
        caption_text = quote_block.has_css?(".cdx-quote__caption") ? quote_block.find(".cdx-quote__caption").text : ""
        quote_text.include?(text) || caption_text.include?(text)
      else
        block.text.include?(text)
      end
    end

    expect(found).to be(true), "Expected to find '#{text}' in editor content"
  end

  def count_editor_blocks
    all(".ce-block").count
  end

  def wait_until_block_count_increases(initial_count)
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.1 until count_editor_blocks > initial_count
    end
  end

  def fill_in_title_and_wait_for_slug(title)
    # Clear any existing value
    title_field = find("#page_title")
    title_field.click
    title_field.send_keys([:control, "a"], :backspace)

    # Type the title character by character
    title.chars.each do |char|
      title_field.send_keys(char)
      sleep 0.1 # Increased delay between characters
    end

    # Ensure the full title is set
    expect(title_field.value).to eq(title)

    # Trigger blur event and wait for slug generation
    title_field.send_keys(:tab)

    # Wait for URL field to have expected value
    expected_slug = title.parameterize
    path_field = find("#page_path", wait: 10)

    # Add debug output
    puts_debug "Title entered: #{title}"
    puts_debug "Expected slug: #{expected_slug}"
    puts_debug "Current path value: #{path_field.value}"

    # Get parent path if one is selected
    parent_path = ""
    if page.has_select?("Parent") && page.has_select?("Parent", selected: /.+/)
      parent_text = page.find("select#page_parent_id option[selected]").text
      if (match = parent_text.match(/.*\((.*)\)$/))
        parent_path = match[1].sub(/\/$/, "") # Remove trailing slash
      end
    end

    # Build full expected path
    full_expected_path = parent_path.empty? ? "/#{expected_slug}" : "#{parent_path}/#{expected_slug}"
    puts_debug "Full expected path: #{full_expected_path}"

    # Wait for the correct value with retries
    5.times do |i|
      if path_field.value == full_expected_path
        break
      else
        puts "[DEBUG] Attempt #{i + 1}: Path not yet correct"
        puts "[DEBUG] Current: #{path_field.value}"
        puts "[DEBUG] Expected: #{full_expected_path}"
        sleep 0.5
        title_field.send_keys(:tab) # Retrigger blur event
      end
    end

    expect(path_field.value).to eq(full_expected_path)
  end

  private

  def debug_editor_state(record = nil)
    return unless ENV["DEBUG"]
    puts_debug "Current URL: #{current_url}"
    puts_debug "Editor container ID we're looking for: #{editor_container_id(record)}"
    puts_debug "Editor container present: #{page.has_css?("[data-controller='editor-form'] .codex-editor")}"
    puts_debug "Hidden field present: #{page.has_css?("[data-editor-form-target='hiddenField']")}"
    puts_debug "Block count: #{all(".ce-block").count}"

    # Debug editor instance
    puts_debug "Editor instance check:"
    begin
      global_editor = page.evaluate_script('typeof window.editor !== "undefined" && window.editor !== null')
      puts_debug "  Global editor exists: #{global_editor}"

      if page.has_css?(".editor-js-holder")
        holder = page.find(".editor-js-holder")
        holder_editor = page.evaluate_script("arguments[0].editorInstance !== null", holder)
        puts_debug "  Holder editor exists: #{holder_editor}"
      else
        puts_debug "  No editor holder found"
      end
    rescue => e
      puts_debug "  Error checking editor: #{e.message}"
    end

    # Debug all elements with ID containing 'editor'
    puts_debug "All editor-related elements:"
    all("[id*='editor']").each do |el|
      puts_debug "  Found element with ID: #{el["id"]}"
    end

    # Debug form elements
    puts_debug "Form elements:"
    all("form").each do |form|
      puts_debug "  Form action: #{form["action"]}"
      puts_debug "  Form data controllers: #{form["data-controller"]}"
    end
  end
end

RSpec.configure do |config|
  config.include EditorHelpers, type: :system
end
