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
/* Editor layout styles */
.codex-editor {
  position: relative !important;
  z-index: 995 !important;
  padding: 0 40px !important; /* Add padding to make room for the + button */
}

.ce-toolbar__content {
  max-width: 100% !important;
  margin: 0 !important;
  position: relative !important;
  z-index: 1000 !important;
  left: 0 !important;
}

.ce-toolbar__plus {
  position: absolute !important;
  left: -30px !important; /* Position + button in the left padding */
  top: 50% !important;
  transform: translateY(-50%) !important;
  z-index: 1001 !important;
  opacity: 1 !important;
  width: 24px !important;
  height: 24px !important;
  margin: 0 !important;
}

.ce-toolbar__actions {
  position: absolute !important;
  right: -30px !important;
  top: 50% !important;
  transform: translateY(-50%) !important;
  z-index: 1001 !important;
}

.ce-block__content {
  max-width: 100% !important;
  margin: 0 !important;
  position: relative !important;
  z-index: 999 !important;
}

/* Ensure proper nesting for content styles to apply */
.codex-editor .codex-editor__redactor {
  position: relative !important;
  padding-bottom: 100px !important;
  z-index: 998 !important;
  margin: 0 !important;
}

/* Remove default editor styles that might interfere */
.ce-header {
  padding: 0 !important;
  margin: 0 !important;
  background: none !important;
  border: none !important;
  position: relative !important;
  z-index: 997 !important;
}

.ce-paragraph {
  padding: 0 !important;
  margin: 0 !important;
  line-height: inherit !important;
  position: relative !important;
  z-index: 997 !important;
}

/* Lists */
.ce-block--list ul,
.ce-block--list ol {
  margin: 0 !important;
  padding-left: inherit !important;
  position: relative !important;
  z-index: 997 !important;
}

.ce-block--list li {
  margin: 0 !important;
  padding-left: inherit !important;
  position: relative !important;
  z-index: 997 !important;
}

/* Ensure editor toolbar is above content */
.ce-toolbar {
  position: absolute !important;
  left: 0 !important;
  width: 100% !important;
  z-index: 1002 !important;
  background: transparent !important;
}

/* Style the block selection */
.ce-block--selected {
  background-color: rgba(16, 64, 113, 0.05) !important;
  border-radius: 4px !important;
  position: relative !important;
  z-index: 996 !important;
}

/* Ensure editor wrapper is above page content */
.ce-block__content-wrapper {
  position: relative !important;
  z-index: 994 !important;
}

/* Ensure popover is above everything */
.ce-popover {
  z-index: 1100 !important;
  position: absolute !important;
}

/* Ensure inline toolbar is above everything */
.ce-inline-toolbar {
  z-index: 1101 !important;
  position: absolute !important;
}

/* Ensure conversion toolbar is above everything */
.ce-conversion-toolbar {
  z-index: 1102 !important;
  position: absolute !important;
}

/* Ensure all editor components are visible and clickable */
.ce-toolbar,
.ce-block,
.ce-block__content,
.ce-toolbar__content,
.ce-toolbar__actions,
.ce-toolbar__plus,
.ce-popover,
.ce-inline-toolbar,
.ce-conversion-toolbar {
  pointer-events: auto !important;
  visibility: visible !important;
  opacity: 1 !important;
}

/* Fix toolbar button visibility */
.ce-toolbar__plus-button,
.ce-toolbar__settings-btn {
  opacity: 1 !important;
  visibility: visible !important;
  pointer-events: auto !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
}

/* Ensure buttons are visible on hover */
.ce-toolbar__plus:hover .ce-toolbar__plus-button,
.ce-toolbar__settings-btn:hover {
  opacity: 1 !important;
  background-color: rgba(16, 64, 113, 0.1) !important;
}`

export const getEditorConfig = (elementId, previousData, doc = document) => {
  // Validate holder element exists
  const holder = doc.getElementById(elementId)
  if (!holder) {
    throw new Error(`Editor holder element ${elementId} not found`)
  }

  // Get the correct window context
  const win = doc.defaultView || window

  const config = {
    holder: elementId,
    data: previousData || {},
    placeholder: 'Click the + button to add content...',
    inlineToolbar: true,
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
          defaultStyle: 'unordered'
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
      table: {
        class: win.Table,
        inlineToolbar: true,
        config: {
          rows: 2,
          cols: 2
        }
      },
      image: {
        class: win.SimpleImage,
        inlineToolbar: true,
        config: {
          placeholder: 'Paste an image URL...'
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
