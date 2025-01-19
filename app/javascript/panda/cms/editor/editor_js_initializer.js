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

  async waitForEditorJS(timeout = 10000) {
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

  /**
   * Wait for a specific tool to be available in window context
   */
  async waitForTool(toolName, timeout = 10000) {
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

  async initializeEditor(element, initialData = {}, editorId = null) {
    try {
      // Wait for EditorJS core to be available with increased timeout
      await this.waitForEditorJS(15000)

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

      // Process initial data to handle list items and other content
      let processedData = initialData
      if (initialData.blocks) {
        processedData = {
          ...initialData,
          blocks: initialData.blocks.map(block => {
            if (block.type === 'list' && block.data && Array.isArray(block.data.items)) {
              return {
                ...block,
                data: {
                  ...block.data,
                  items: block.data.items.map(item => {
                    // Handle both string items and object items
                    if (typeof item === 'string') {
                      return {
                        content: item,
                        items: []
                      }
                    } else if (item.content) {
                      return {
                        content: item.content,
                        items: Array.isArray(item.items) ? item.items : []
                      }
                    } else {
                      return {
                        content: String(item),
                        items: []
                      }
                    }
                  })
                }
              }
            }
            return block
          })
        }
      }

      console.debug('[Panda CMS] Processed initial data:', processedData)

      // Create editor configuration
      const config = {
        holder: holder,
        data: processedData,
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
          }
        },
        onChange: (api, event) => {
          console.debug('[Panda CMS] Editor content changed:', { api, event })
          // Save content to data attributes
          api.saver.save().then((outputData) => {
            const jsonString = JSON.stringify(outputData)
            element.dataset.editablePreviousData = btoa(jsonString)
            element.dataset.editableContent = jsonString
            element.dataset.editableInitialized = 'true'
          })
        },
        onReady: () => {
          console.debug('[Panda CMS] Editor ready with data:', processedData)
          element.dataset.editableInitialized = 'true'
          holder.editorInstance = editor
        },
        onError: (error) => {
          console.error('[Panda CMS] Editor error:', error)
          element.dataset.editableInitialized = 'false'
          throw error
        }
      }

      // Remove any undefined tools from the config
      config.tools = Object.fromEntries(
        Object.entries(config.tools)
          .filter(([_, value]) => value?.class !== undefined)
      )

      console.debug('[Panda CMS] Creating editor with config:', config)

      // Create editor instance with extended timeout
      return new Promise((resolve, reject) => {
        try {
          // Add timeout for initialization
          const timeoutId = setTimeout(() => {
            reject(new Error('Editor initialization timeout'))
          }, 15000) // Increased to 15 seconds

          // Create editor instance with onReady callback
          const editor = new win.EditorJS({
            ...config,
            onReady: () => {
              console.debug('[Panda CMS] Editor ready with data:', processedData)
              clearTimeout(timeoutId)
              holder.editorInstance = editor
              element.dataset.editableInitialized = 'true'
              resolve(editor)
            },
            onChange: (api, event) => {
              console.debug('[Panda CMS] Editor content changed:', { api, event })
              // Save content to data attributes
              api.saver.save().then((outputData) => {
                const jsonString = JSON.stringify(outputData)
                element.dataset.editablePreviousData = btoa(jsonString)
                element.dataset.editableContent = jsonString
              })
            },
            onError: (error) => {
              console.error('[Panda CMS] Editor error:', error)
              element.dataset.editableInitialized = 'false'
              clearTimeout(timeoutId)
              reject(error)
            }
          })

          // Add error handler
          editor.isReady
            .then(() => {
              console.debug('[Panda CMS] Editor is ready')
              element.dataset.editableInitialized = 'true'
            })
            .catch((error) => {
              console.error('[Panda CMS] Editor failed to initialize:', error)
              element.dataset.editableInitialized = 'false'
              clearTimeout(timeoutId)
              reject(error)
            })
        } catch (error) {
          element.dataset.editableInitialized = 'false'
          reject(error)
        }
      })
    } catch (error) {
      console.error('[Panda CMS] Error initializing editor:', error)
      throw error
    }
  }
}
