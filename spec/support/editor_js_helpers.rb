module EditorJSHelpers
  class << self
    attr_accessor :editor_ready_cache
  end

  def wait_for_editor(timeout: 10)
    # Use cached result if available and recent
    cache_key = "#{page.current_path}-#{Time.now.to_i / 5}" # Cache for 5 seconds
    if EditorJSHelpers.editor_ready_cache&.dig(cache_key)
      if ENV['DEBUG']
        debug "Using cached editor ready state"
      end
      return true
    end

    if ENV['DEBUG']
      debug "Waiting for editor..."
    end

    # First check if we're in an iframe context
    in_iframe = page.evaluate_script('window.top !== window.self')

    Timeout.timeout(timeout) do
      # Parallel check for all required components
      result = page.evaluate_async_script(<<~JS)
        var done = arguments[0];
        Promise.all([
          // Check for required tools
          Promise.all([
            !!window.EditorJS,
            !!window.Header,
            !!window.Paragraph
          ]),
          // Check for DOM elements
          Promise.resolve().then(() => {
            const container = document.querySelector('[data-controller="editor-form"]');
            const iframeContainer = document.querySelector('[data-controller="editor-iframe"]');
            return {
              form: !!container,
              iframe: !!iframeContainer,
              editorContainer: container?.querySelector('[data-editor-form-target="editorContainer"]'),
              toolbar: document.querySelector('.ce-toolbar'),
              block: document.querySelector('.ce-block')
            };
          }),
          // Check editor instance
          Promise.resolve().then(() => {
            const editor = window.editor;
            return {
              instance: !!editor,
              ready: editor?.isReady,
              hasBlocks: !!editor?.blocks,
              canGetBlocks: typeof editor?.blocks?.getBlocksCount === 'function'
            };
          })
        ]).then(([tools, elements, editor]) => {
          done({
            tools: {
              hasEditor: tools[0],
              hasHeader: tools[1],
              hasParagraph: tools[2],
              missing: [
                !tools[0] && 'EditorJS',
                !tools[1] && 'Header',
                !tools[2] && 'Paragraph'
              ].filter(Boolean)
            },
            elements,
            editor
          });
        }).catch(error => {
          done({ error: error.message });
        });
      JS

      if result.nil? || result['error']
        error_msg = result&.dig('error') || 'Failed to check editor state'
        raise "Editor check failed: #{error_msg}"
      end

      # Quick fail if tools are missing
      missing = Array(result.dig('tools', 'missing'))
      if missing.any?
        raise "Required editor components not loaded: #{missing.join(', ')}"
      end

      # For iframe context, we only need basic editor functionality
      if in_iframe
        editor_ready = result.dig('editor', 'instance') &&
                      result.dig('editor', 'hasBlocks') &&
                      result.dig('elements', 'iframe')

        if editor_ready
          EditorJSHelpers.editor_ready_cache ||= {}
          EditorJSHelpers.editor_ready_cache[cache_key] = true
          return true
        end
      end

      # For regular context, we need all UI elements
      editor_ready = result.dig('editor', 'instance') &&
                    result.dig('editor', 'hasBlocks') &&
                    result.dig('editor', 'canGetBlocks') &&
                    result.dig('elements', 'form') &&
                    result.dig('elements', 'editorContainer')

      # If editor is ready but UI elements are missing, try to force a redraw
      if editor_ready && (!result.dig('elements', 'toolbar') || !result.dig('elements', 'block'))
        redraw_result = page.evaluate_async_script(<<~JS)
          var done = arguments[0];
          try {
            const editor = window.editor;
            editor.blocks.clear()
              .then(() => editor.blocks.insert('paragraph'))
              .then(() => done({ success: true }))
              .catch(error => done({ error: error.message }));
          } catch (e) {
            done({ error: e.message });
          }
        JS

        if redraw_result.nil? || redraw_result['error']
          error_msg = redraw_result&.dig('error') || 'Failed to redraw editor'
          raise "Editor redraw failed: #{error_msg}"
        end

        # Wait a short time for redraw
        sleep 0.05
      end

      # Cache successful result
      if editor_ready
        EditorJSHelpers.editor_ready_cache ||= {}
        EditorJSHelpers.editor_ready_cache[cache_key] = true
      end

      editor_ready
    end
  rescue Timeout::Error, StandardError => e
    debug "Editor initialization failed: #{e.message}"
    debug "Current URL: #{page.current_url}"
    debug "Current Path: #{page.current_path}"
    debug "Page Title: #{page.title}"
    debug "DOM state:"
    debug page.evaluate_script(<<~JS)
      (function() {
        const editor = window.editor;
        return {
          editorForm: !!document.querySelector('[data-controller="editor-form"]'),
          editorIframe: !!document.querySelector('[data-controller="editor-iframe"]'),
          toolbar: !!document.querySelector('.ce-toolbar'),
          blocks: document.querySelectorAll('.ce-block').length,
          editorInstance: !!editor,
          ready: editor?.isReady,
          hasBlocks: !!editor?.blocks,
          canSave: typeof editor?.save === 'function',
          tools: {
            EditorJS: !!window.EditorJS,
            Header: !!window.Header,
            Paragraph: !!window.Paragraph
          }
        };
      })()
    JS
    raise e
  end

  def open_plus_menu
    if ENV['DEBUG']
      debug "Opening plus menu..."
    end

    # Try to find and click the last block with a shorter timeout
    result = page.evaluate_script(<<~JS, wait: 1)
      (function() {
        const blocks = document.querySelectorAll('.ce-block');
        const lastBlock = blocks[blocks.length - 1];
        if (lastBlock) {
          lastBlock.click();
          return { clicked: true, blockCount: blocks.length };
        }
        return { error: 'No blocks found' };
      })();
    JS

    if result['error']
      raise "Failed to click block: #{result['error']}"
    end

    if ENV['DEBUG']
      debug "Block count: #{result['blockCount']}"
    end

    # Try to find and click the plus button
    plus_result = page.evaluate_script(<<~JS, wait: 1)
      (function() {
        const plus = document.querySelector('.ce-toolbar__plus');
        if (plus) {
          plus.click();
          return { clicked: true };
        }
        return { error: 'Plus button not found' };
      })();
    JS

    if plus_result['error']
      raise "Failed to click plus button: #{plus_result['error']}"
    end

    # Wait for popover with shorter timeout
    expect(page).to have_css(".ce-popover--opened", wait: 3)

    if ENV['DEBUG']
      tools = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll('.ce-popover--opened [data-item-name]'))
          .map(el => el.textContent.trim())
      JS
      debug "Available tools: #{tools.inspect}"
    end
  end

  def add_editor_content(type:, content:)
    # Try direct insertion first with shorter timeout
    result = page.evaluate_async_script(<<~JS, wait: 1)
      var done = arguments[0];
      Promise.resolve().then(() => {
        const container = document.querySelector('[data-controller="editor-form"]') ||
                        document.querySelector('[data-editable-kind="rich_text"]');
        const editor = container?.editorInstance;

        if (!editor?.isReady) {
          return { error: 'Editor not ready' };
        }

        return editor.blocks.insert('#{type}', #{content.to_json})
          .then(() => ({ success: true }))
          .catch(error => ({ error: error.message }));
      }).then(done);
    JS

    if result['error']
      if ENV['DEBUG']
        debug "Direct insertion failed: #{result['error']}, falling back to UI"
      end
      add_content_via_ui(type: type, content: content)
    end

    # Verify content was added with shorter timeout
    verify_text = case type
                 when 'paragraph', 'header'
                   content[:text].to_s
                 when 'list'
                   content[:items].first.to_s
                 when 'quote'
                   [content[:text], content[:caption]].join(' ')
                 else
                   content.values.first.to_s
                 end

    expect(page).to have_content(verify_text, wait: 1)
  end

  def add_editor_paragraph(text)
    add_editor_content(type: 'paragraph', content: { text: text })
  end

  def add_editor_header(text)
    add_editor_content(type: 'header', content: { text: text, level: 2 })
  end

  def add_editor_list(items, type: :unordered)
    add_editor_content(type: 'list', content: { style: type, items: items })
  end

  def add_editor_quote(text, caption)
    add_editor_content(type: 'quote', content: { text: text, caption: caption })
  end

  private

  def add_content_via_ui(type:, content:)
    # Try UI interaction with shorter timeouts
    result = page.evaluate_async_script(<<~JS, wait: 1)
      var done = arguments[0];
      Promise.resolve().then(() => {
        const blocks = document.querySelectorAll('.ce-block');
        const lastBlock = blocks[blocks.length - 1];
        if (!lastBlock) return { error: 'No blocks found' };

        lastBlock.click();
        const plus = document.querySelector('.ce-toolbar__plus');
        if (!plus) return { error: 'Plus button not found' };

        plus.click();
        return { success: true };
      })
      .catch(error => ({ error: error.message }))
      .then(done);
    JS

    if result['error']
      raise "Failed to open plus menu: #{result['error']}"
    end

    # Wait for popover with shorter timeout
    expect(page).to have_css(".ce-popover--opened", wait: 1)

    within(".ce-popover--opened") do
      find("[data-item-name='#{type}']").click
    end

    case type
    when 'paragraph', 'header'
      page.driver.browser.keyboard.type(content[:text].to_s)
      page.driver.browser.keyboard.type(:enter)
    when 'quote'
      page.driver.browser.keyboard.type(content[:text].to_s)
      page.driver.browser.keyboard.type(:enter)
      page.driver.browser.keyboard.type(content[:caption].to_s)
      page.driver.browser.keyboard.type(:enter)
    when 'list'
      content[:items].each do |item|
        page.driver.browser.keyboard.type(item.to_s)
        page.driver.browser.keyboard.type(:enter)
      end
    end
  end

  def clear_editor
    # Try to clear editor with shorter timeout
    result = page.evaluate_async_script(<<~JS, wait: 1)
      var done = arguments[0];
      Promise.resolve().then(() => {
        const container = document.querySelector('[data-controller="editor-form"]');
        const editor = container?.editorInstance;

        if (!editor?.isReady) {
          return { error: 'Editor not ready' };
        }

        return editor.blocks.clear()
          .then(() => editor.save())
          .then(savedData => {
            const input = container.querySelector('[data-editor-form-target="hiddenField"]');
            if (input) {
              input.value = JSON.stringify({ blocks: [], source: "editorJS" });
              input.dispatchEvent(new Event('change', { bubbles: true }));
            }
            return { success: true };
          })
          .catch(error => ({ error: error.message }));
      }).then(done);
    JS

    if result['error']
      raise "Failed to clear editor: #{result['error']}"
    end

    # Verify the editor is empty with shorter timeout
    expect(page).to have_css(".codex-editor--empty", wait: 1)
  end

  def expect_editor_to_have_content(text)
    # Check content with shorter timeout
    result = page.evaluate_async_script(<<~JS, wait: 2)
      var done = arguments[0];
      Promise.resolve().then(() => {
        const container = document.querySelector('[data-controller="editor-form"]');
        const editor = container?.editorInstance;

        if (!editor?.isReady) {
          return { error: 'Editor not ready' };
        }

        return Promise.all([
          Promise.resolve(Array.from(document.querySelectorAll('.ce-block'))
            .map(block => block.textContent.trim())),
          editor.save()
        ]).then(([blocks, savedData]) => ({
          blocks,
          savedData,
          hasContent: blocks.some(content => content.includes(#{text.to_json}))
        }));
      })
      .catch(error => ({ error: error.message }))
      .then(done);
    JS

    if ENV['DEBUG']
      debug "Content check result: #{result.inspect}"
    end

    if result['error']
      raise "Failed to check editor content: #{result['error']}"
    end

    expect(result['hasContent']).to(
      be(true),
      "Expected to find '#{text}' in editor blocks: #{result['blocks'].inspect}\nEditor data: #{result['savedData'].inspect}"
    )
  end

  def debug_editor_state
    if ENV['DEBUG']
      state = page.evaluate_script(<<~JS, wait: 1)
        (function() {
          const container = document.querySelector('[data-controller="editor-form"]');
          const editor = container?.editorInstance;
          const state = {
            hasContainer: !!container,
            hasEditor: !!editor,
            isReady: editor?.isReady,
            blockCount: editor?.blocks?.getBlocksCount?.() || 0,
            hasToolbar: !!document.querySelector('.ce-toolbar'),
            blocks: Array.from(document.querySelectorAll('.ce-block')).map(block => ({
              type: block.dataset.type,
              isEmpty: block.classList.contains('ce-block--empty'),
              hasToolbar: !!block.querySelector('.ce-toolbar'),
              content: block.textContent.trim().substring(0, 50) + (block.textContent.length > 50 ? '...' : '')
            })),
            tools: {
              EditorJS: !!window.EditorJS,
              Header: !!window.Header,
              Paragraph: !!window.Paragraph,
              List: !!window.NestedList,
              Quote: !!window.Quote,
              Table: !!window.Table,
              Image: !!window.SimpleImage,
              Embed: !!window.Embed
            }
          };
          console.debug('[Panda CMS] Editor state:', state);
          return state;
        })();
      JS

      debug "Editor state: #{JSON.pretty_generate(state)}"
    end
  end
end

RSpec.configure do |config|
  config.include EditorJSHelpers, type: :system
end
