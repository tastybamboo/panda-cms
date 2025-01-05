import { Controller } from "@hotwired/stimulus"
import { PlainTextEditor } from "panda/cms/editor/plain_text_editor"
import { EditorJSInitializer } from "panda/cms/editor/editor_js_initializer"
import { EDITOR_JS_RESOURCES, EDITOR_JS_CSS } from "panda/cms/editor/editor_js_config"
import { ResourceLoader } from "panda/cms/editor/resource_loader"

export default class extends Controller {
  static values = {
    pageId: Number,
    adminPath: String,
    autosave: Boolean
  }

  connect() {
    console.debug("[Panda CMS] EditorIframe controller connected")
    this.frame = this.element
    this.setupControls()
    this.setupFrame()
    this.editors = []
    this.editorsInitialized = {
      plain: false,
      rich: false
    }
    this.setupSlideoverHandling()
  }

  setupControls() {
    // Create editor controls if they don't exist
    if (!parent.document.querySelector('.editor-controls')) {
      const controls = parent.document.createElement('div')
      controls.className = 'editor-controls'
      parent.document.body.appendChild(controls)
    }

    // Create save button if it doesn't exist
    if (!parent.document.getElementById('saveEditableButton')) {
      const saveButton = parent.document.createElement('a')
      saveButton.id = 'saveEditableButton'
      saveButton.href = '#'
      saveButton.textContent = 'Save Changes'
      saveButton.className = 'btn btn-primary'
      parent.document.querySelector('.editor-controls').appendChild(saveButton)
    }
  }

  setupFrame() {
    // Always show the frame initially to ensure it's visible for tests
    this.frame.style.display = ""
    this.frame.style.width = "100%"
    this.frame.style.height = "100%"
    this.frame.style.minHeight = "500px"

    // Set up iframe stacking context
    this.frame.style.position = "relative"
    this.frame.style.zIndex = "1" // Lower z-index so it doesn't block UI

    // Get CSRF token
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ""

    // Setup frame load handler
    this.frame.addEventListener("load", async () => {
      console.debug("[Panda CMS] Frame loaded")
      this.frameDocument = this.frame.contentDocument || this.frame.contentWindow.document
      this.body = this.frameDocument.body
      this.head = this.frameDocument.head

      // Ensure iframe content is properly positioned but doesn't block UI
      this.body.style.position = "relative"
      this.body.style.zIndex = "1"

      // Add a class to help identify this frame's editors
      const frameId = this.frame.id || Math.random().toString(36).substring(7)
      this.frame.setAttribute('data-editor-frame-id', frameId)
      this.body.setAttribute('data-editor-frame-id', frameId)

      // Prevent default context menu behavior
      this.body.addEventListener('contextmenu', (event) => {
        // Only prevent default if the target is part of the editor
        if (event.target.closest('.codex-editor')) {
          event.preventDefault()
        }
      })

      // Set up error handling for the iframe
      this.frameDocument.defaultView.onerror = (message, source, lineno, colno, error) => {
        // Ignore context menu errors
        if (message.includes('anchor.getAttribute') && source.includes('script.js')) {
          return true // Prevent error from propagating
        }

        // Relay other errors to the parent window
        const fullMessage = `iFrame Error: ${message} (${source}:${lineno}:${colno})`
        console.error(fullMessage, error)

        // Throw the error in the parent context for Cuprite to catch
        setTimeout(() => {
          throw new Error(fullMessage)
        }, 0)

        return false // Let other errors propagate
      }

      // Set up unhandled rejection handling for the iframe
      this.frameDocument.defaultView.onunhandledrejection = (event) => {
        // Ignore context menu related rejections
        if (event.reason?.toString().includes('anchor.getAttribute')) {
          return
        }

        const fullMessage = `iFrame Unhandled Promise Rejection: ${event.reason}`
        console.error(fullMessage)

        // Throw the error in the parent context for Cuprite to catch
        setTimeout(() => {
          throw event.reason
        }, 0)
      }

      // Initialize editors after frame is loaded
      await this.initializeEditors()
    })
  }

  ensureFrameVisibility() {
    // Force frame to be visible
    this.frame.style.display = ""

    // Check dimensions and fix if needed
    if (this.frame.offsetWidth === 0 || this.frame.offsetHeight === 0) {
      console.warn("[Panda CMS] iFrame has zero dimensions, fixing...")
      this.frame.style.width = "100%"
      this.frame.style.height = "100%"
      this.frame.style.minHeight = "500px"
    }

    // Log visibility state
    console.debug("[Panda CMS] Frame visibility state:", {
      display: this.frame.style.display,
      width: this.frame.offsetWidth,
      height: this.frame.offsetHeight,
      visible: this.frame.offsetParent !== null
    })
  }

  async initializeEditors() {
    console.debug("[Panda CMS] Starting editor initialization")

    // Get all editable elements
    const plainTextElements = this.body.querySelectorAll('[data-editable-kind="plain_text"], [data-editable-kind="markdown"], [data-editable-kind="html"]')
    const richTextElements = this.body.querySelectorAll('[data-editable-kind="rich_text"]')

    console.debug(`[Panda CMS] Found ${plainTextElements.length} plain text elements and ${richTextElements.length} rich text elements`)

    // Always ensure frame is visible
    this.ensureFrameVisibility()

    // Initialize editors if they exist
    if (plainTextElements.length > 0 || richTextElements.length > 0) {
      this.initializePlainTextEditors()
      await this.loadEditorResources()
      await this.initializeRichTextEditors()
    }
  }

  async loadEditorResources() {
    console.debug("[Panda CMS] Loading editor resources in iframe...")
    try {
      // First load EditorJS core
      const editorCore = EDITOR_JS_RESOURCES[0]
      await ResourceLoader.loadScript(this.frameDocument, this.head, editorCore)

      // Wait for EditorJS to be available
      await this.waitForEditorJS()

      // Load CSS directly
      await ResourceLoader.embedCSS(this.frameDocument, this.head, EDITOR_JS_CSS)

      // Map of tool names to their expected global class names and URLs
      const toolMapping = {
        'paragraph': { className: 'Paragraph', url: EDITOR_JS_RESOURCES.find(r => r.includes('paragraph')) },
        'header': { className: 'Header', url: EDITOR_JS_RESOURCES.find(r => r.includes('header')) },
        'nested-list': { className: 'NestedList', url: EDITOR_JS_RESOURCES.find(r => r.includes('nested-list')) },
        'quote': { className: 'Quote', url: EDITOR_JS_RESOURCES.find(r => r.includes('quote')) },
        'simple-image': { className: 'SimpleImage', url: EDITOR_JS_RESOURCES.find(r => r.includes('simple-image')) },
        'table': { className: 'Table', url: EDITOR_JS_RESOURCES.find(r => r.includes('table')) },
        'embed': { className: 'Embed', url: EDITOR_JS_RESOURCES.find(r => r.includes('embed')) }
      }

      // Load all tool scripts first
      await Promise.all(Object.entries(toolMapping).map(async ([toolName, { url }]) => {
        try {
          console.debug(`[Panda CMS] Loading tool script: ${toolName} from ${url}`)
          await ResourceLoader.loadScript(this.frameDocument, this.head, url)
        } catch (error) {
          console.error(`[Panda CMS] Failed to load tool script: ${toolName}`, error)
          throw error
        }
      }))

      // Then verify all tools are available
      await Promise.all(Object.entries(toolMapping).map(async ([toolName, { className }]) => {
        try {
          console.debug(`[Panda CMS] Verifying tool: ${toolName} -> ${className}`)
          await new Promise((resolve, reject) => {
            const timeout = setTimeout(() => {
              reject(new Error(`Timeout waiting for ${toolName} (${className}) to load`))
            }, 10000)

            const check = () => {
              const toolClass = this.frameDocument.defaultView[className]
              if (toolClass) {
                console.debug(`[Panda CMS] Tool ${toolName} -> ${className} loaded:`, {
                  toolClass: !!toolClass,
                  window: this.frameDocument.defaultView === window ? 'main' : 'iframe',
                  frameId: this.frame.getAttribute('data-editor-frame-id')
                })
                clearTimeout(timeout)
                resolve()
              } else {
                setTimeout(check, 100)
              }
            }
            check()
          })
        } catch (error) {
          console.error(`[Panda CMS] Failed to verify tool: ${toolName}`, error)
          throw error
        }
      }))

      // Final verification of all tools
      const missingTools = []
      for (const [toolName, { className }] of Object.entries(toolMapping)) {
        if (!this.frameDocument.defaultView[className]) {
          missingTools.push(`${toolName}@${toolMapping[toolName].url?.split('@')[1] || 'unknown'}`)
        }
      }

      if (missingTools.length > 0) {
        const error = new Error(`Missing required Editor.js tools: ${missingTools.join(', ')}`)
        console.error("[Panda CMS]", error)
        throw error
      }

      // Set flags to indicate tools are initialized
      this.frameDocument.defaultView.EDITOR_JS_TOOLS_INITIALIZED = true
      this.frame.setAttribute('data-editor-tools-initialized', 'true')
      this.body.setAttribute('data-editor-tools-initialized', 'true')

      console.debug("[Panda CMS] Editor resources loaded in iframe", {
        frameId: this.frame.getAttribute('data-editor-frame-id'),
        toolsInitialized: true,
        availableTools: Object.entries(toolMapping).map(([name, { className }]) => ({
          name,
          className,
          loaded: !!this.frameDocument.defaultView[className]
        }))
      })
    } catch (error) {
      console.error("[Panda CMS] Error loading editor resources in iframe:", error)
      throw error
    }
  }

  waitForEditorJS() {
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error("Timeout waiting for EditorJS to load"))
      }, 10000)

      const check = () => {
        if (this.frameDocument.defaultView.EditorJS) {
          clearTimeout(timeout)
          resolve()
        } else {
          setTimeout(check, 100)
        }
      }
      check()
    })
  }

  waitForTool(toolName) {
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error(`Timeout waiting for ${toolName} to load`))
      }, 10000)

      // Map tool names to their expected global class names
      const toolClassMap = {
        'paragraph': 'Paragraph',
        'header': 'Header',
        'nested-list': 'NestedList',
        'quote': 'Quote',
        'simple-image': 'SimpleImage',
        'table': 'Table',
        'embed': 'Embed'
      }

      const check = () => {
        // Get the expected class name for this tool
        const expectedClassName = toolClassMap[toolName] || toolName
        const toolClass = this.frameDocument.defaultView[expectedClassName]

        console.debug(`[Panda CMS] Checking for tool ${toolName} -> ${expectedClassName}:`, {
          toolFound: !!toolClass,
          availableClasses: Object.keys(this.frameDocument.defaultView).filter(key =>
            key.includes('Header') ||
            key.includes('Paragraph') ||
            key.includes('List') ||
            key.includes('Quote') ||
            key.includes('Image') ||
            key.includes('Table') ||
            key.includes('Embed')
          )
        })

        if (toolClass) {
          clearTimeout(timeout)
          resolve()
        } else {
          setTimeout(check, 100)
        }
      }
      check()
    })
  }

  initializePlainTextEditors() {
    this.editorsInitialized.plain = false
    const plainTextElements = this.body.querySelectorAll('[data-editable-kind="plain_text"], [data-editable-kind="markdown"], [data-editable-kind="html"]')
    console.debug(`[Panda CMS] Found ${plainTextElements.length} plain text elements`)

    plainTextElements.forEach(element => {
      const editor = new PlainTextEditor(element, this.frameDocument, {
        autosave: this.autosaveValue,
        adminPath: this.adminPathValue,
        csrfToken: this.csrfToken
      })
      this.editors.push(editor)
    })

    this.editorsInitialized.plain = true
    this.checkAllEditorsInitialized()
  }

  async initializeRichTextEditors() {
    this.editorsInitialized.rich = false
    const richTextElements = this.body.querySelectorAll('[data-editable-kind="rich_text"]')
    console.debug(`[Panda CMS] Found ${richTextElements.length} rich text elements`)

    if (richTextElements.length > 0) {
      try {
        // Verify Editor.js is available in the iframe context
        if (!this.frameDocument.defaultView.EditorJS) {
          const error = new Error("Editor.js not loaded in iframe context")
          console.error("[Panda CMS]", error)
          throw error
        }

        const initializer = new EditorJSInitializer(this.frameDocument, true)

        // Initialize each editor sequentially to avoid race conditions
        const editors = []
        for (const element of richTextElements) {
          try {
            // Create holder element before initialization
            const holderId = `editor-${Math.random().toString(36).substr(2, 9)}`
            const holderElement = this.frameDocument.createElement('div')
            holderElement.id = holderId
            holderElement.className = 'editor-js-holder codex-editor'
            element.appendChild(holderElement)

            // Verify the holder element exists
            const verifyHolder = this.frameDocument.getElementById(holderId)
            if (!verifyHolder) {
              const error = new Error(`Failed to create editor holder element ${holderId}`)
              console.error("[Panda CMS]", error)
              throw error
            }

            console.debug(`[Panda CMS] Created editor holder: ${holderId}`, {
              exists: !!verifyHolder,
              parent: element.id || 'no-id',
              editorJSAvailable: !!this.frameDocument.defaultView.EditorJS
            })

            // Initialize editor with empty data
            const editor = await initializer.initialize(holderElement, {}, holderId)

            // Set up save handler for this editor
            const saveButton = parent.document.getElementById('saveEditableButton')
            if (saveButton) {
              saveButton.addEventListener('click', async () => {
                try {
                  const outputData = await editor.save()
                  outputData.source = "editorJS"

                  const pageId = element.getAttribute("data-editable-page-id")
                  const blockContentId = element.getAttribute("data-editable-block-content-id")

                  const response = await fetch(`${this.adminPathValue}/pages/${pageId}/block_contents/${blockContentId}`, {
                    method: "PATCH",
                    headers: {
                      "Content-Type": "application/json",
                      "X-CSRF-Token": this.csrfToken
                    },
                    body: JSON.stringify({ content: outputData })
                  })

                  if (!response.ok) {
                    throw new Error('Save failed')
                  }

                  this.handleSuccess()
                } catch (error) {
                  console.error("[Panda CMS] Save error:", error)
                  this.handleError(error)
                }
              })
            } else {
              console.warn("[Panda CMS] Save button not found")
            }

            editors.push(editor)
          } catch (error) {
            console.error("[Panda CMS] Editor initialization error:", error)
            throw error
          }
        }

        // Filter out any null editors and add the valid ones
        const validEditors = editors.filter(editor => editor !== null)
        this.editors.push(...validEditors)

        // If we didn't get any valid editors, that's an error
        if (validEditors.length === 0) {
          const error = new Error("No editors were successfully initialized")
          console.error("[Panda CMS]", error)
          throw error
        }

        this.editorsInitialized.rich = true
        this.checkAllEditorsInitialized()
      } catch (error) {
        console.error("[Panda CMS] Rich text editor initialization failed:", error)
        throw error
      }
    } else {
      this.editorsInitialized.rich = true
      this.checkAllEditorsInitialized()
    }
  }

  checkAllEditorsInitialized() {
    console.log("[Panda CMS] Editor initialization status:", this.editorsInitialized)

    // Always ensure frame is visible
    this.ensureFrameVisibility()
  }

  handleError(error) {
    const errorMessage = parent.document.getElementById("errorMessage")
    if (errorMessage) {
      errorMessage.getElementsByClassName('flash-message-text')[0].textContent = error
      errorMessage.classList.remove("hidden")
      setTimeout(() => {
        errorMessage.classList.add("hidden")
      }, 3000)
    }
    console.error("[Panda CMS] Error:", error)

    // Throw the error to fail the test
    throw error
  }

  handleSuccess() {
    const successMessage = parent.document.getElementById("successMessage")
    if (successMessage) {
      successMessage.classList.remove("hidden")
      setTimeout(() => {
        successMessage.classList.add("hidden")
      }, 3000)
    }
  }

  setupSlideoverHandling() {
    // Watch for slideover toggle
    const slideoverToggle = document.getElementById('slideover-toggle')
    const slideover = document.getElementById('slideover')

    if (slideoverToggle && slideover) {
      const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.attributeName === 'class') {
            const isVisible = !slideover.classList.contains('hidden')
            this.adjustFrameZIndex(isVisible)
          }
        })
      })

      observer.observe(slideover, { attributes: true })

      // Initial state
      this.adjustFrameZIndex(!slideover.classList.contains('hidden'))
    }
  }

  adjustFrameZIndex(slideoverVisible) {
    if (slideoverVisible) {
      // Lower z-index when slideover is visible
      this.frame.style.zIndex = "0"
      if (this.body) this.body.style.zIndex = "0"
    } else {
      // Restore z-index when slideover is hidden
      this.frame.style.zIndex = "1"
      if (this.body) this.body.style.zIndex = "1"
    }
    console.debug("[Panda CMS] Adjusted frame z-index:", {
      slideoverVisible,
      frameZIndex: this.frame.style.zIndex,
      bodyZIndex: this.body?.style.zIndex
    })
  }
}
