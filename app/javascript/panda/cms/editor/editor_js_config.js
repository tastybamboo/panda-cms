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
.ce-toolbar__content {
  margin: 0 !important;
  margin-left: 40px;
  max-width: 100% !important;
  width: 100% !important;
}

.ce-block__content {
  max-width: 100%;
  margin: 0 !important;
  margin-left: 10px !important;
}

/* Ensure proper nesting for content styles to apply */
.codex-editor .codex-editor__redactor {
  position: relative;
}

.codex-editor .codex-editor__redactor .ce-block {
  position: relative;
}

.codex-editor .codex-editor__redactor .ce-block .ce-block__content {
  position: relative;
}

/* Remove default editor styles that might interfere */
.ce-header {
  padding: 0 !important;
  margin: 0 !important;
  background: none !important;
  border: none !important;
}

.ce-paragraph {
  padding: 0 !important;
  margin: 0 !important;
  line-height: inherit !important;
}

/* Lists */
.ce-block--list ul,
.ce-block--list ol {
  margin: 0;
  padding-left: inherit;
}

.ce-block--list li {
  margin: 0;
  padding-left: inherit;
}

/* Ensure editor toolbar is above content */
.ce-toolbar {
  z-index: 100;
}

/* Style the block selection */
.ce-block--selected {
  background-color: rgba(16, 64, 113, 0.05);
  border-radius: 4px;
}`

export const getEditorConfig = (elementId, previousData, doc = document) => {
  // Validate holder element exists
  const holder = doc.getElementById(elementId)
  if (!holder) {
    throw new Error(`Editor holder element ${elementId} not found`)
  }

  const config = {
    holder: elementId,
    data: previousData || {},
    placeholder: 'Click the + button to add content...',
    inlineToolbar: true,
    tools: {
      header: {
        class: window.Header,
        inlineToolbar: true,
        config: {
          placeholder: 'Enter a header',
          levels: [1, 2, 3, 4, 5, 6],
          defaultLevel: 2
        }
      },
      paragraph: {
        class: window.Paragraph,
        inlineToolbar: true,
        config: {
          placeholder: 'Start writing or press Tab to add content...'
        }
      },
      list: {
        class: window.NestedList,
        inlineToolbar: true,
        config: {
          defaultStyle: 'unordered'
        }
      },
      quote: {
        class: window.Quote,
        inlineToolbar: true,
        config: {
          quotePlaceholder: 'Enter a quote',
          captionPlaceholder: 'Quote\'s author'
        }
      },
      table: {
        class: window.Table,
        inlineToolbar: true,
        config: {
          rows: 2,
          cols: 2
        }
      },
      image: {
        class: window.SimpleImage,
        inlineToolbar: true,
        config: {
          placeholder: 'Paste an image URL...'
        }
      },
      embed: {
        class: window.Embed,
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
