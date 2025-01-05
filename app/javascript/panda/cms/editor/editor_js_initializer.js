import { ResourceLoader } from "panda/cms/editor/resource_loader"
import { EDITOR_JS_RESOURCES, EDITOR_JS_CSS, getEditorConfig } from "panda/cms/editor/editor_js_config"
import { CSSExtractor } from "panda/cms/editor/css_extractor"

export class EditorJSInitializer {
  constructor(document, withinIFrame = false) {
    this.document = document
    this.withinIFrame = withinIFrame
  }

  /**
   * Initializes the EditorJS instance for a given element.
   * This method loads necessary resources and returns the JavaScript code for initializing the editor.
   *
   * @param {HTMLElement} element - The DOM element to initialize the editor on
   * @param {Object} initialData - The initial data for the editor
   * @param {string} editorId - The ID to use for the editor holder
   * @returns {Promise<EditorJS>} A promise that resolves to the editor instance
   */
  async initialize(element, initialData = {}, editorId = null) {
    await this.loadResources()
    const result = await this.initializeEditor(element, initialData, editorId)
    return result
  }

  /**
   * Gets the application's styles from its configured stylesheet
   * @returns {Promise<string>} The extracted CSS rules
   */
  async getApplicationStyles() {
    try {
      // Get the configured stylesheet URL, defaulting to Tailwind Rails default
      const stylesheetUrl = window.PANDA_CMS_CONFIG?.stylesheetUrl || '/assets/application.tailwind.css'

      // Fetch the CSS content
      const response = await fetch(stylesheetUrl)
      const css = await response.text()
      return CSSExtractor.getEditorStyles(css)
    } catch (error) {
      return ''
    }
  }

  /**
   * Loads the necessary resources for the EditorJS instance.
   * This method fetches the required scripts and stylesheets and embeds them into the document.
   */
  async loadResources() {
    try {
      // First load EditorJS core
      const editorCore = EDITOR_JS_RESOURCES[0]
      await ResourceLoader.loadScript(this.document, this.document.head, editorCore)

      // Wait for EditorJS to be available
      await this.waitForEditorJS()

      // Load CSS directly
      await ResourceLoader.embedCSS(this.document, this.document.head, EDITOR_JS_CSS)

      // Then load all tools sequentially to ensure proper initialization order
      for (const resource of EDITOR_JS_RESOURCES.slice(1)) {
        try {
          await ResourceLoader.loadScript(this.document, this.document.head, resource)
          // Extract tool name from resource URL
          const toolName = resource.split('/').pop().split('@')[0]
          // Wait for tool to be initialized
          const toolClass = await this.waitForTool(toolName)

          // If this is the nested-list tool, also make it available as 'list'
          if (toolName === 'nested-list') {
            const win = this.document.defaultView || window
            win.List = toolClass
          }

          console.debug(`[Panda CMS] Successfully loaded tool: ${toolName}`)
        } catch (error) {
          console.error(`[Panda CMS] Failed to load tool: ${resource}`, error)
          throw error
        }
      }

      console.debug('[Panda CMS] All tools successfully loaded and verified')
    } catch (error) {
      console.error('[Panda CMS] Error loading Editor.js resources:', error)
      throw error
    }
  }

  async initializeEditor(element, initialData = {}, editorId = null) {
    try {
      // Wait for EditorJS core to be available
      await this.waitForEditorJS()

      // Get the window context (either iframe or parent)
      const win = this.document.defaultView || window

      // Create a unique ID for this editor instance if not provided
      const uniqueId = editorId || `editor-${Math.random().toString(36).substring(2)}`

      // Check if editor already exists
      const existingEditor = element.querySelector('.codex-editor')
      if (existingEditor) {
        console.debug('[Panda CMS] Editor already exists, cleaning up...')
        existingEditor.remove()
      }

      // Create a holder div for the editor
      const holder = this.document.createElement("div")
      holder.id = uniqueId
      holder.classList.add("editor-js-holder")
      element.appendChild(holder)

      // Get previous data from the data attribute if available
      let previousData = initialData
      // Get the parent element with the data attribute
      const parentElement = element.closest('[data-editable-previous-data]')
      const previousDataAttr = parentElement ? parentElement.getAttribute('data-editable-previous-data') : null
      console.debug('[Panda CMS] Parent element:', parentElement)
      console.debug('[Panda CMS] Previous data attribute:', previousDataAttr)

      if (previousDataAttr) {
        try {
          // Decode Base64 data
          const decodedData = atob(previousDataAttr)
          console.debug('[Panda CMS] Decoded data:', decodedData)
          const parsed = JSON.parse(decodedData)

          // Ensure we have the required structure
          if (parsed.blocks) {
            // Process blocks to handle list data properly
            parsed.blocks = parsed.blocks.map(block => {
              if (block.type === 'list') {
                console.debug('[Panda CMS] Processing list block:', block)
                // Create a temporary div to decode HTML entities
                const div = this.document.createElement('div')
                return {
                  ...block,
                  data: {
                    ...block.data,
                    items: block.data.items.map(item => {
                      div.innerHTML = item
                      const content = div.innerHTML
                      console.debug('[Panda CMS] Decoded list item:', content)
                      return {
                        content,
                        items: []
                      }
                    })
                  }
                }
              } else if (block.type === 'paragraph' && block.data && block.data.text) {
                // Create a temporary div to decode HTML entities in paragraphs
                const div = this.document.createElement('div')
                div.innerHTML = block.data.text
                return {
                  ...block,
                  data: {
                    ...block.data,
                    text: div.innerHTML
                  }
                }
              }
              return block
            })
            previousData = parsed
            console.debug('[Panda CMS] Processed data:', previousData)
          } else {
            console.warn('[Panda CMS] Parsed data missing blocks array:', parsed)
            // Initialize with empty blocks array if missing
            previousData = { blocks: [], time: Date.now(), version: "2.28.2" }
          }
        } catch (error) {
          console.error('[Panda CMS] Error parsing previous data:', error)
          // Initialize with empty blocks array on error
          previousData = { blocks: [], time: Date.now(), version: "2.28.2" }
        }
      } else {
        console.debug('[Panda CMS] No previous data attribute found')
        // Initialize with empty blocks array if no data
        previousData = { blocks: [], time: Date.now(), version: "2.28.2" }
      }

      // Create editor configuration
      const config = {
        holder: holder,
        data: previousData,
        placeholder: 'Click to start writing...',
        tools: {
          paragraph: {
            class: win.Paragraph,
            inlineToolbar: true,
            config: {
              preserveBlank: true,
              placeholder: 'Click to start writing...'
            }
          },
          header: {
            class: win.Header,
            inlineToolbar: true,
            config: {
              placeholder: 'Enter a header',
              levels: [1, 2, 3, 4, 5, 6],
              defaultLevel: 2
            }
          },
          'list': {  // Register as list instead of nested-list
            class: win.NestedList,
            inlineToolbar: true,
            config: {
              defaultStyle: 'unordered',
              enableLineBreaks: true,
              inlineToolbar: true,
              convertTo: 'list',
              preserveBlank: true,
              enableHTML: true
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

      console.debug('[Panda CMS] Creating editor with config:', config)

      // Create editor instance
      return new Promise((resolve, reject) => {
        try {
          // Add timeout for initialization
          const timeoutId = setTimeout(() => {
            reject(new Error('Editor initialization timeout'))
          }, 5000)

          // Create editor instance with onReady callback
          const editor = new win.EditorJS({
            ...config,
            onReady: () => {
              console.debug('[Panda CMS] Editor ready with data:', previousData)
              clearTimeout(timeoutId)
              holder.editorInstance = editor
              resolve(editor)
            }
          })
        } catch (error) {
          clearTimeout(timeoutId)
          reject(error)
        }
      })
    } catch (error) {
      console.error('[Panda CMS] Error initializing editor:', error)
      throw error
    }
  }

  /**
   * Wait for a specific tool to be available in window context
   */
  async waitForTool(toolName, timeout = 5000) {
    if (!toolName) {
      console.error('[Panda CMS] Invalid tool name provided')
      return null
    }

    // Clean up tool name to handle npm package format
    const cleanToolName = toolName.split('/').pop().replace('@', '')

    const toolMapping = {
      'paragraph': 'Paragraph',
      'header': 'Header',
      'nested-list': 'NestedList',
      'list': 'NestedList',
      'quote': 'Quote',
      'simple-image': 'SimpleImage',
      'table': 'Table',
      'embed': 'Embed'
    }

    const globalToolName = toolMapping[cleanToolName] || cleanToolName
    const start = Date.now()

    while (Date.now() - start < timeout) {
      const win = this.document.defaultView || window
      if (win[globalToolName] && typeof win[globalToolName] === 'function') {
        // If this is the NestedList tool, make it available as both list and nested-list
        if (globalToolName === 'NestedList') {
          win.List = win[globalToolName]
        }
        console.debug(`[Panda CMS] Successfully loaded tool: ${globalToolName}`)
        return win[globalToolName]
      }
      await new Promise(resolve => setTimeout(resolve, 100))
    }
    throw new Error(`[Panda CMS] Timeout waiting for tool: ${cleanToolName} (${globalToolName})`)
  }

  /**
   * Wait for EditorJS core to be available in window context
   */
  async waitForEditorJS(timeout = 5000) {
    console.debug('[Panda CMS] Waiting for EditorJS core...')
    const start = Date.now()
    while (Date.now() - start < timeout) {
      if (typeof this.document.defaultView.EditorJS === 'function') {
        console.debug('[Panda CMS] EditorJS core is ready')
        return
      }
      await new Promise(resolve => setTimeout(resolve, 100))
    }
    throw new Error('[Panda CMS] Timeout waiting for EditorJS')
  }
}
