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
          // Wait for tool to be initialized
          const toolName = resource.split('@')[0].split('/').pop()
          await this.waitForTool(toolName)
          console.debug(`[Panda CMS] Successfully loaded tool: ${toolName}`)
        } catch (error) {
          console.error(`[Panda CMS] Failed to load tool: ${resource}`, error)
          throw error
        }
      }

      // Verify tools are loaded with proper mapping
      const toolMapping = {
        'paragraph': 'Paragraph',
        'header': 'Header',
        'nested-list': 'NestedList',
        'quote': 'Quote',
        'simple-image': 'SimpleImage',
        'table': 'Table',
        'embed': 'Embed'
      }

      // Debug output of loaded tools
      console.debug('[Panda CMS] Checking loaded tools...')
      const loadedTools = Object.entries(toolMapping).map(([urlName, globalName]) => {
        const isLoaded = typeof this.document.defaultView[globalName] === 'function'
        console.debug(`[Panda CMS] Tool ${urlName} -> ${globalName}: ${isLoaded ? 'LOADED' : 'NOT LOADED'}`)
        return { urlName, globalName, isLoaded }
      })

      const missingTools = loadedTools.filter(tool => !tool.isLoaded)
      if (missingTools.length > 0) {
        const missingNames = missingTools.map(t => `${t.urlName} (${t.globalName})`).join(', ')
        throw new Error(`Not all Editor.js tools were properly loaded. Missing: ${missingNames}`)
      }

      console.debug('[Panda CMS] All tools successfully loaded and verified')
    } catch (error) {
      console.error('[Panda CMS] Error loading Editor.js resources:', error)
      throw error
    }
  }

  async initializeEditor(element, initialData = {}, editorId = null) {
    // Generate a consistent holder ID if not provided
    const holderId = editorId || `editor-${element.id || Math.random().toString(36).substr(2, 9)}`

    // Create or find the holder element in the correct document context
    let holderElement = this.document.getElementById(holderId)
    if (!holderElement) {
      // Create the holder element in the correct document context
      holderElement = this.document.createElement('div')
      holderElement.id = holderId
      holderElement.className = 'editor-js-holder codex-editor'

      // Append to the element and force a reflow
      element.appendChild(holderElement)
      void holderElement.offsetHeight // Force a reflow
    }

    // Verify the holder element exists in the correct document context
    const verifyHolder = this.document.getElementById(holderId)
    if (!verifyHolder) {
      throw new Error(`Failed to create editor holder element ${holderId}`)
    }

    // Clear any existing content in the holder
    holderElement.innerHTML = ''

    // Add source to initial data
    if (initialData && !initialData.source) {
      initialData.source = "editorJS"
    }

    // Get the base config but pass our document context
    const config = getEditorConfig(holderId, initialData, this.document)

    // Override specific settings for iframe context
    const editorConfig = {
      ...config,
      holder: holderElement, // Use element reference instead of ID
      minHeight: 1, // Prevent auto-height issues in iframe
      autofocus: false, // Prevent focus issues
      logLevel: 'ERROR', // Only show errors
      tools: {
        ...config.tools,
        // Ensure tools use the correct window context
        paragraph: { ...config.tools.paragraph, class: this.document.defaultView.Paragraph },
        header: { ...config.tools.header, class: this.document.defaultView.Header },
        list: { ...config.tools.list, class: this.document.defaultView.NestedList },
        quote: { ...config.tools.quote, class: this.document.defaultView.Quote },
        table: { ...config.tools.table, class: this.document.defaultView.Table },
        image: { ...config.tools.image, class: this.document.defaultView.SimpleImage },
        embed: { ...config.tools.embed, class: this.document.defaultView.Embed }
      }
    }

    // Create editor instance directly
    const editor = new this.document.defaultView.EditorJS({
      ...editorConfig,
      onReady: () => {
        // Store the editor instance globally for testing
        if (this.withinIFrame) {
          this.document.defaultView.editor = editor
        } else {
          window.editor = editor
        }

        // Mark editor as ready
        editor.isReady = true

        // Force redraw of toolbar and blocks
        setTimeout(async () => {
          try {
            const toolbar = holderElement.querySelector('.ce-toolbar')
            const blockWrapper = holderElement.querySelector('.ce-block')

            if (!toolbar || !blockWrapper) {
              // Clear and insert a new block to force UI update
              await editor.blocks.clear()
              await editor.blocks.insert('paragraph')

              // Force a redraw by toggling display
              holderElement.style.display = 'none'
              void holderElement.offsetHeight
              holderElement.style.display = ''
            }

            // Call the ready hook if it exists
            if (typeof window.onEditorJSReady === 'function') {
              window.onEditorJSReady(editor)
            }
          } catch (error) {
            console.error('Error during editor redraw:', error)
          }
        }, 100)
      },
      onChange: async (api, event) => {
        try {
          // Save the current editor data
          const outputData = await api.saver.save()
          outputData.source = "editorJS"
          const contentJson = JSON.stringify(outputData)

          if (!this.withinIFrame) {
            // For form-based editors, update the hidden input
            const form = element.closest('[data-controller="editor-form"]')
            if (form) {
              const hiddenInput = form.querySelector('[data-editor-form-target="hiddenField"]')
              if (hiddenInput) {
                hiddenInput.value = contentJson
                hiddenInput.dataset.initialContent = contentJson
                hiddenInput.dispatchEvent(new Event('change', { bubbles: true }))
              }
            }
          } else {
            // For iframe-based editors, update the element's data attribute
            element.setAttribute('data-content', contentJson)
            element.dispatchEvent(new Event('change', { bubbles: true }))

            // Get the save button from parent window
            const saveButton = parent.document.getElementById('saveEditableButton')
            if (saveButton) {
              // Store the current content on the save button for later use
              saveButton.dataset.pendingContent = contentJson

              // Add click handler if not already added
              if (!saveButton.hasAttribute('data-handler-attached')) {
                saveButton.setAttribute('data-handler-attached', 'true')
                saveButton.addEventListener('click', async () => {
                  try {
                    const pageId = element.getAttribute("data-editable-page-id")
                    const blockContentId = element.getAttribute("data-editable-block-content-id")
                    const pendingContent = JSON.parse(saveButton.dataset.pendingContent || '{}')

                    const response = await fetch(`${this.adminPathValue}/pages/${pageId}/block_contents/${blockContentId}`, {
                      method: "PATCH",
                      headers: {
                        "Content-Type": "application/json",
                        "X-CSRF-Token": this.csrfToken
                      },
                      body: JSON.stringify({ content: pendingContent })
                    })

                    if (!response.ok) {
                      throw new Error('Save failed')
                    }

                    // Clear pending content after successful save
                    delete saveButton.dataset.pendingContent
                  } catch (error) {
                    console.error('Error saving content:', error)
                  }
                })
              }
            }
          }
        } catch (error) {
          console.error('Error in onChange handler:', error)
        }
      }
    })

    // Store editor instance on the holder element to maintain reference
    holderElement.editorInstance = editor

    if (!this.withinIFrame) {
      // Store the editor instance on the controller element for potential future reference
      const form = element.closest('[data-controller="editor-form"]')
      if (form) {
        form.editorInstance = editor
      }
    } else {
      // For iframe editors, store the instance on the element itself
      element.editorInstance = editor
    }

    // Return a promise that resolves when the editor is ready
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error('Editor initialization timed out'))
      }, 30000)

      const checkReady = () => {
        if (editor.isReady) {
          clearTimeout(timeout)
          resolve(editor)
        } else {
          setTimeout(checkReady, 100)
        }
      }
      checkReady()
    })
  }

  /**
   * Wait for a specific tool to be available in window context
   */
  async waitForTool(toolName, timeout = 5000) {
    const toolMapping = {
      'paragraph': 'Paragraph',
      'header': 'Header',
      'nested-list': 'NestedList',
      'quote': 'Quote',
      'simple-image': 'SimpleImage',
      'table': 'Table',
      'embed': 'Embed'
    }

    const globalToolName = toolMapping[toolName]
    if (!globalToolName) {
      console.warn(`[Panda CMS] No mapping found for tool: ${toolName}`)
      return
    }

    console.debug(`[Panda CMS] Waiting for tool ${toolName} -> ${globalToolName}...`)
    const start = Date.now()
    while (Date.now() - start < timeout) {
      if (typeof this.document.defaultView[globalToolName] === 'function') {
        console.debug(`[Panda CMS] Tool ${toolName} -> ${globalToolName} is ready`)
        return
      }
      await new Promise(resolve => setTimeout(resolve, 100))
    }
    throw new Error(`[Panda CMS] Timeout waiting for tool: ${toolName} (${globalToolName})`)
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
