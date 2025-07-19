# frozen_string_literal: true

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
          return {
            success: !!(
              win.EditorJS &&
              win.Paragraph &&
              win.Header &&
              win.NestedList &&
              win.Quote &&
              win.Table
            )
          };
        } catch (e) {
          return { success: false, error: e.message };
        }
      })();
    JS

    result["success"]
  end

  def wait_for_editor(record = nil)
    @editor_container_id = editor_container_id(record)

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
    puts "DEBUG: Looking for editor container: #{@editor_container_id}" if ENV["DEBUG"]

    # First find the editor container
    editor_container = if @editor_container_id.start_with?("#")
      context.find("##{@editor_container_id.sub("#", "")}")
    else
      context.find(@editor_container_id)
    end

    puts "DEBUG: Found editor container" if ENV["DEBUG"]

    # For page editing (iframe context), we don't have a form with hidden field
    # Instead, we check for the editable div with data-controller="editor-js"
    if @editor_container_id == 'div[data-editable-kind="rich_text"]'
      puts "DEBUG: In iframe context, looking for editor-js controller" if ENV["DEBUG"]

      # Wait for the iframe to load and the editor div to appear
      max_wait_attempts = 100
      wait_attempts = 0
      editor_div = nil

      while wait_attempts < max_wait_attempts && editor_div.nil?
        begin
          editor_div = context.find('div[data-controller="editor-js"]', wait: 1)
          puts "DEBUG: Found editor div with data-controller" if ENV["DEBUG"]
          break
        rescue Capybara::ElementNotFound
          wait_attempts += 1
          sleep 0.2

          # Debug iframe loading
          if ENV["DEBUG"] && wait_attempts % 10 == 0
            puts "DEBUG: Attempt #{wait_attempts}, checking iframe content..."
            content = context.evaluate_script("document.body.innerHTML.length")
            puts "DEBUG: Iframe content length: #{content}"
          end
        end
      end

      if editor_div.nil?
        puts "DEBUG: Could not find editor div after #{wait_attempts} attempts" if ENV["DEBUG"]
        return false
      end

      # Debug current state
      if ENV["DEBUG"]
        puts "DEBUG: Editor div attributes:"
        puts "  data-editable-initialized: #{editor_div['data-editable-initialized']}"
        puts "  data-editor-js-initialized-value: #{editor_div['data-editor-js-initialized-value']}"

        # Check what's in the DOM
        html_content = context.evaluate_script("document.body.innerHTML")
        puts "DEBUG: Page HTML length: #{html_content.length}"

        # Check for script tags
        scripts = context.evaluate_script("Array.from(document.scripts).map(s => s.src).filter(s => s)")
        puts "DEBUG: Loaded scripts: #{scripts.join(', ')}"

        # Check for EditorJS availability
        editorjs_available = context.evaluate_script("typeof EditorJS !== 'undefined'")
        puts "DEBUG: EditorJS available: #{editorjs_available}"
      end

      # Check if editor is initialized by specifically waiting for editorInstance on holder
      max_attempts = 150
      attempts = 0

      while attempts < max_attempts
        initialized = context.evaluate_script(<<~JS)
          (function() {
            const editorDiv = document.querySelector('[data-controller="editor-js"]');
            if (!editorDiv) return false;

            // Check if EditorJS resources are available
            const hasEditorJS = typeof EditorJS !== 'undefined';
            const hasTools = typeof Paragraph !== 'undefined' && typeof Header !== 'undefined';

            if (!hasEditorJS || !hasTools) return false;

            // The most reliable indicator is the editor instance on the holder
            const holder = document.querySelector('.editor-js-holder');
            if (!holder) return false;

            // Check if the editor instance exists and has the save method
            const hasEditorInstance = holder.editorInstance !== null &&
                                    holder.editorInstance !== undefined &&
                                    typeof holder.editorInstance.save === 'function';

            return hasEditorInstance;
          })();
        JS

        if ENV["DEBUG"] && attempts % 15 == 0
          puts "DEBUG: Attempt #{attempts}, initialized: #{initialized}"
        end

        return true if initialized

        attempts += 1
        sleep 0.15
      end

      puts "DEBUG: Editor initialization failed after #{attempts} attempts" if ENV["DEBUG"]
      return false
    else
      # For form context (posts, etc.), check for hidden field
      context.find("input[data-editor-form-target='hiddenField']", visible: false)

      # Check if editor exists
      editor_exists = context.evaluate_script("window.editor !== null && window.editor !== undefined")

      # If not found, try finding it on the holder element within the container
      unless editor_exists
        begin
          # Scope the search to the editor container
          editor_holder = editor_container.find(".codex-editor", match: :first)
          editor_exists = context.evaluate_script("arguments[0].editorInstance !== null", editor_holder)
        rescue Capybara::ElementNotFound
          # Editor holder not found
        end
      end

      editor_exists
    end
  end

  def wait_for_editor_initialization(record = nil)
    wait_for_editor(record)

    within(editor_container_id(record)) do
      # Wait for the editor to be fully loaded
      if record.is_a?(Panda::CMS::Page)
        # For pages in iframe, wait for the editor div to be initialized
        find('[data-controller="editor-js"]', wait: 10)

        # Wait for editor to be ready
        max_attempts = 50
        attempts = 0

        while attempts < max_attempts
          ready = page.evaluate_script(<<~JS)
            (function() {
              const editorDiv = document.querySelector('[data-controller="editor-js"]');
              return editorDiv && (
                document.querySelector('.codex-editor') !== null ||
                window.editor !== null && window.editor !== undefined
              );
            })();
          JS

          break if ready

          attempts += 1
          sleep 0.1
        end
      else
        # For other contexts, check for empty editor
        find(".codex-editor--empty").click if page.has_css?(".codex-editor--empty", wait: 1)
      end
    end
  end

  def open_plus_menu
    # Click the last block first if any blocks exist
    all(".ce-block").last.click if page.has_css?(".ce-block")

    # Open plus menu
    find(".ce-toolbar__plus").click
    expect(page).to have_css(".ce-popover--opened", wait: 1)
  end

  def add_editor_header(text, level = 1, record = nil)
    wait_for_editor_initialization(record)

    within(editor_container_id(record)) do
      # If editor is empty, we need to click it first
      find(".codex-editor--empty").click if page.has_css?(".codex-editor--empty")

      # Open plus menu and select header
      open_plus_menu
      within(".ce-popover--opened") do
        find("[data-item-name='header']", wait: 0.1).click
      end

      # Wait for block to be created and find it
      header_block = find(".ce-block", wait: 0.2)

      # Change header level if needed
      if level > 1
        header_block.click
        find(".ce-inline-toolbar [data-level='#{level}']", wait: 0.1).click
      end

      # Add the header text using normal user input
      within(header_block) do
        input = find("[contenteditable]", wait: 0.1)
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
    within(editor_container_id(record)) do
      # Wait for editor to be initialized differently based on context
      if record.is_a?(Panda::CMS::Page)
        # For pages in iframe, wait for the editable div and codex editor
        find('[data-controller="editor-js"]', wait: 10)

        # Wait for codex editor to be ready
        max_attempts = 50
        attempts = 0

        while attempts < max_attempts
          editor_ready = page.evaluate_script(<<~JS)
            (function() {
              return document.querySelector('.codex-editor') !== null;
            })();
          JS

          break if editor_ready

          attempts += 1
          sleep 0.1
        end

        # Click on the editor to activate it if it's empty
        if page.has_css?('.codex-editor--empty', wait: 1)
          find('.codex-editor--empty').click
          sleep 0.2
        end
      else
        # For other contexts, wait for the traditional editor
        find(".codex-editor[data-editor-initialized='true']", wait: 10)
      end

      if replace_first && page.has_css?(".ce-block")
        # Click the first paragraph to focus it
        first_block = find(".ce-block")
        first_block.click
        # Clear existing content
        first_block.find("[contenteditable]").send_keys([:control, "a"], :backspace)
        # Enter new content
        first_block.find("[contenteditable]").set(text)
      else
        # For iframe context, we might need to create the first block
        if record.is_a?(Panda::CMS::Page) && !page.has_css?(".ce-block")
          # Wait for codex editor to be available and click to create first block
          if page.has_css?('.codex-editor', wait: 5)
            find('.codex-editor').click
            sleep 0.5
          elsif page.has_css?('.editor-js-holder', wait: 5)
            find('.editor-js-holder').click
            sleep 0.5
          end
        end

        # Check if we need to add a new block or use existing empty one
        if page.has_css?(".ce-block") && find_all(".ce-block").count == 1 && find(".ce-block [contenteditable]").text.blank?
          # Use existing empty block
          within(find(".ce-block")) do
            find("[contenteditable]").set(text)
          end
        else
          # Open the plus menu if we're adding a new block
          open_plus_menu
          within(".ce-popover--opened") do
            find("[data-item-name='paragraph']").click
          end

          # Find the last block and enter text
          within(all(".ce-block").last) do
            find("[contenteditable]").set(text)
          end
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
        find("[data-item-name='list']", wait: 0.1).click
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
      # Open plus menu and select quote
      open_plus_menu
      within(".ce-popover--opened") do
        find("[data-item-name='quote']", wait: 5).click
      end

      # Wait for the quote block to appear and be ready
      quote_block = find(".cdx-quote", wait: 10)

      # Wait a moment for the block to be fully initialized
      sleep 0.3

      # Enter the quote text
      quote_input = quote_block.find(".cdx-quote__text", wait: 5)
      quote_input.click

      # Clear any placeholder text and enter our text
      quote_input.send_keys([:control, "a"], :backspace) if quote_input.text.present?
      quote_input.send_keys(text)

      if caption
        # Enter the caption text
        caption_input = quote_block.find(".cdx-quote__caption", wait: 5)
        caption_input.click

        # Clear any placeholder text and enter our caption
        caption_input.send_keys([:control, "a"], :backspace) if caption_input.text.present?
        caption_input.send_keys(caption)
      end

      # Move focus away to ensure changes are saved
      page.send_keys(:tab)
      sleep 0.5

      # Brief verification that content was set
      final_quote_text = quote_block.find(".cdx-quote__text").text
      expect(final_quote_text).to include(text)

      if caption
        final_caption_text = quote_block.find(".cdx-quote__caption").text
        expect(final_caption_text).to include(caption)
      end
    end
  end

  def expect_editor_content_to_include(text, record = nil)
    wait_for_editor_initialization(record)

    # For iframe context, we need to wait a bit longer for content to be rendered
    if record.is_a?(Panda::CMS::Page)
      # Wait for the editor to have content with more patience
      max_attempts = 50
      attempts = 0

      while attempts < max_attempts && !page.has_css?(".ce-block")
        sleep 0.2
        attempts += 1
      end
    end

    # Wait for blocks to be rendered with more patience
    expect(page).to have_css(".ce-block", wait: 10)

    # Get all blocks
    blocks = all(".ce-block")

    # Check if text is found in any block
    found = blocks.any? do |block|
      if block.has_css?(".cdx-quote")
        quote_block = block.find(".cdx-quote")
        quote_text = quote_block.has_css?(".cdx-quote__text") ? quote_block.find(".cdx-quote__text").text : ""
        caption_text = quote_block.has_css?(".cdx-quote__caption") ? quote_block.find(".cdx-quote__caption").text : ""
        quote_text.include?(text) || caption_text.include?(text)
      else
        block.text.include?(text)
      end
    end

    expect(found).to be(true), "Expected to find '#{text}' in editor content. Available blocks: #{blocks.map(&:text).join(', ')}"
  end

  def count_editor_blocks
    all(".ce-block").count
  end

  def wait_until_block_count_increases(initial_count)
    Timeout.timeout(2) do
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
    end

    # Ensure the full title is set
    expect(title_field.value).to eq(title)

    # Trigger blur event and wait for slug generation
    title_field.send_keys(:tab)

    # Wait for URL field to have expected value
    expected_slug = title.parameterize
    path_field = find("#page_path", wait: 0.1)

    # Add debug output
    puts_debug "Title entered: #{title}"
    puts_debug "Expected slug: #{expected_slug}"
    puts_debug "Current path value: #{path_field.value}"

    # Get parent path if one is selected
    parent_path = ""
    if page.has_select?("Parent") && page.has_select?("Parent", selected: /.+/)
      parent_text = page.find("select#page_parent_id option[selected]").text
      if (match = parent_text.match(/.*\((.*)\)$/))
        parent_path = match[1].sub(%r{/$}, "") # Remove trailing slash
      end
    end

    # Build full expected path
    full_expected_path = parent_path.empty? ? "/#{expected_slug}" : "#{parent_path}/#{expected_slug}"
    puts_debug "Full expected path: #{full_expected_path}"

    # Wait for the correct value with retries
    5.times do |_i|
      break if path_field.value == full_expected_path

      sleep 0.1
      title_field.send_keys(:tab) # Retrigger blur event
    end

    expect(path_field.value).to eq(full_expected_path)
  end

  # Helper method for triggering slug generation in forms
  def trigger_slug_generation(title)
    fill_in "Title", with: title

    # Manually generate the slug instead of relying on JavaScript
    slug = create_slug_from_title(title)

    # Check if a parent is selected to determine the full path
    parent_select = find("select[name='page[parent_id]']", wait: 1)
    if parent_select.value.present? && parent_select.value != ""
      # Get the parent path from the selected option text
      selected_option = parent_select.find("option[value='#{parent_select.value}']")
      if selected_option.text =~ /\((.*)\)$/
        parent_path = $1.gsub(/\/$/, "") # Remove trailing slash
        fill_in "URL", with: "#{parent_path}/#{slug}"
      else
        fill_in "URL", with: "/#{slug}"
      end
    else
      fill_in "URL", with: "/#{slug}"
    end
  end

  private

  # Create a slug from a title (matches the JavaScript implementation)
  def create_slug_from_title(title)
    return "" if title.nil? || title.strip.empty?

    title.strip
      .downcase
      .gsub(/[^a-z0-9]+/, "-")
      .gsub(/^-+|-+$/, "")
  end

  # Helper for clicking on multiple selectors
  def click_on_selectors(*selectors)
    selectors.each do |selector|
      find(selector).click
      sleep 0.1
    end
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
