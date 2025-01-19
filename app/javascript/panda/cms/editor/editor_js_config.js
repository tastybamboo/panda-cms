export const EDITOR_JS_RESOURCES = [
  "https://cdn.jsdelivr.net/npm/@editorjs/editorjs@2.28.2",
  "https://cdn.jsdelivr.net/npm/@editorjs/paragraph@2.11.3",
  "https://cdn.jsdelivr.net/npm/@editorjs/header@2.8.1",
  "https://cdn.jsdelivr.net/npm/@editorjs/nested-list@1.4.2",
  "https://cdn.jsdelivr.net/npm/@editorjs/quote@2.6.0",
  "https://cdn.jsdelivr.net/npm/@editorjs/simple-image@1.6.0",
  "https://cdn.jsdelivr.net/npm/@editorjs/table@2.3.0",
  "https://cdn.jsdelivr.net/npm/@editorjs/embed@2.7.0"
]

// Allow applications to add their own resources
if (window.PANDA_CMS_EDITOR_JS_RESOURCES) {
  EDITOR_JS_RESOURCES.push(...window.PANDA_CMS_EDITOR_JS_RESOURCES)
}

export const EDITOR_JS_CSS = `
  .codex-editor {
    position: relative;
  }
  .codex-editor::before {
    content: '';
    position: absolute;
    left: 0;
    top: 0;
    bottom: 0;
    width: 65px;
    margin-right: 5px;
    background-color: #f9fafb;
    border-right: 2px dashed #e5e7eb;
    z-index: 0;
  }
  .ce-block {
    padding-left: 70px;
    position: relative;
    min-height: 40px;
    margin: 0;
    padding-bottom: 1em;
  }
  .ce-block__content {
    position: relative;
    max-width: none;
    margin: 0;
  }
  .ce-paragraph {
    padding: 0;
    line-height: 1.6;
    min-height: 1.6em;
    margin: 0;
  }
  /* Override inherited heading styles */
  .ce-header h1,
  .ce-header h2,
  .ce-header h3,
  .ce-header h4,
  .ce-header h5,
  .ce-header h6 {
    margin: 0;
    padding: 0;
    line-height: 1.6;
    font-weight: 600;
  }
  .ce-header h1 { font-size: 2em; }
  .ce-header h2 { font-size: 1.5em; }
  .ce-header h3 { font-size: 1.17em; }
  .ce-header h4 { font-size: 1em; }
  .ce-header h5 { font-size: 0.83em; }
  .ce-header h6 { font-size: 0.67em; }

  .codex-editor__redactor {
    padding-bottom: 150px !important;
    min-height: 100px !important;
  }
  /* Base toolbar styles */
  .ce-toolbar {
    left: 0 !important;
    right: auto !important;
    background: none !important;
    position: absolute !important;
    width: 65px !important;
    height: 40px !important;
    display: flex !important;
    align-items: center !important;
    justify-content: flex-start !important;
    padding: 0 !important;
    margin-left: -70px !important;
    margin-top: -5px !important;
    opacity: 1 !important;
    visibility: visible !important;
    pointer-events: all !important;
    z-index: 2 !important;
  }
  /* Ensure toolbar is visible for all blocks */
  .ce-block .ce-toolbar {
    display: flex !important;
    opacity: 1 !important;
    visibility: visible !important;
  }
  .ce-toolbar__content {
    max-width: none;
    left: 70px !important;
    display: flex !important;
    position: relative !important;
  }
  .ce-toolbar__actions {
    position: relative !important;
    left: 5px !important;
    opacity: 1 !important;
    visibility: visible !important;
    background: transparent !important;
    z-index: 2;
    display: flex !important;
    align-items: center !important;
    gap: 5px !important;
    height: 40px !important;
    padding: 0 !important;
  }
  .ce-toolbar__plus {
    position: relative !important;
    left: 0px !important;
    opacity: 1 !important;
    visibility: visible !important;
    background: transparent !important;
    border: none !important;
    z-index: 2;
    display: block !important;
  }
  .ce-toolbar__settings-btn {
    position: relative !important;
    left: -10px !important;
    opacity: 1 !important;
    visibility: visible !important;
    background: transparent !important;
    border: none !important;
    z-index: 2;
    display: block !important;
  }
  /* Style the search input */
  .ce-popover__search {
    padding-left: 3px !important;
  }
  .ce-popover__search input {
    outline: none !important;
    box-shadow: none !important;
    border: none !important;
  }
  .ce-popover__search input::placeholder {
    content: 'Search';
  }
  /* Ensure popups still work */
  .ce-popover {
    z-index: 4;
  }
  .ce-inline-toolbar {
    z-index: 3;
  }
  /* Override any hiding behavior */
  .ce-toolbar--closed,
  .ce-toolbar--opened,
  .ce-toolbar--showed {
    display: flex !important;
    opacity: 1 !important;
    visibility: visible !important;
  }
  /* Force toolbar to show on every block */
  .ce-block:not(:focus):not(:hover) .ce-toolbar,
  .ce-block--selected .ce-toolbar,
  .ce-block--focused .ce-toolbar,
  .ce-block--hover .ce-toolbar {
    opacity: 1 !important;
    visibility: visible !important;
    display: flex !important;
  }

  /* Ensure last block has bottom spacing */
  .ce-block:last-child {
    padding-bottom: 2em;
  }

  /* Reset all block type margins */
  .ce-header,
  .ce-paragraph,
  .ce-quote,
  .ce-list {
    margin: 0 !important;
    padding: 0 !important;
  }
`

export const getEditorConfig = (elementId, previousData, doc = document) => {
  // Validate holder element exists
  const holder = doc.getElementById(elementId)
  if (!holder) {
    throw new Error(`Editor holder element ${elementId} not found`)
  }

  // Get the correct window context
  const win = doc.defaultView || window

  // Ensure we have a clean holder element
  holder.innerHTML = ""

  const config = {
    holder: elementId,
    data: previousData || {},
    placeholder: 'Click the + button to add content...',
    inlineToolbar: true,
    onChange: () => {
      // Ensure the editor is properly initialized before handling changes
      if (holder && holder.querySelector('.codex-editor')) {
        const event = new Event('editor:change', { bubbles: true })
        holder.dispatchEvent(event)
      }
    },
    i18n: {
      toolbar: {
        filter: {
          placeholder: 'Search'
        }
      }
    },
    tools: {
      header: {
        class: win.Header,
        inlineToolbar: true,
        config: {
          placeholder: 'Enter a header',
          levels: [1, 2, 3, 4, 5, 6],
          defaultLevel: 2
        }
      },
      paragraph: {
        class: win.Paragraph,
        inlineToolbar: true,
        config: {
          placeholder: 'Start writing or press Tab to add content...'
        }
      },
      list: {
        class: win.NestedList,
        inlineToolbar: true,
        config: {
          defaultStyle: 'unordered',
          enableLineBreaks: true
        }
      },
      quote: {
        class: win.Quote,
        inlineToolbar: true,
        config: {
          quotePlaceholder: 'Enter a quote',
          captionPlaceholder: 'Quote\'s author'
        }
      },
      image: {
        class: win.SimpleImage,
        inlineToolbar: true,
        config: {
          placeholder: 'Paste an image URL...'
        }
      },
      table: {
        class: win.Table,
        inlineToolbar: true,
        config: {
          rows: 2,
          cols: 2
        }
      },
      embed: {
        class: win.Embed,
        inlineToolbar: true,
        config: {
          services: {
            youtube: true,
            vimeo: true
          }
        }
      }
    }
  }

  // Remove any undefined tools from the config
  config.tools = Object.fromEntries(
    Object.entries(config.tools)
      .filter(([_, value]) => value?.class !== undefined)
      .map(([name, tool]) => {
        if (!tool.class) {
          throw new Error(`Tool ${name} has no class defined`)
        }
        return [name, tool]
      })
  )

  // Allow applications to customize the config through Ruby
  if (window.PANDA_CMS_EDITOR_JS_CONFIG) {
    Object.assign(config.tools, window.PANDA_CMS_EDITOR_JS_CONFIG)
  }

  // Allow applications to customize the config through JavaScript
  if (typeof window.customizeEditorJS === 'function') {
    window.customizeEditorJS(config)
  }

  return config
}
