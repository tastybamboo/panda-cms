import { Controller } from "@hotwired/stimulus"
import { PlainTextEditor } from "panda/cms/editor/plain_text_editor"
import { EditorJSInitializer } from "panda/cms/editor/editor_js_initializer"

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

    // Get CSRF token
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ""

    // Setup frame load handler
    this.frame.addEventListener("load", async () => {
      console.debug("[Panda CMS] Frame loaded")
      this.frameDocument = this.frame.contentDocument || this.frame.contentWindow.document
      this.body = this.frameDocument.body
      this.head = this.frameDocument.head

      // Set up error handling for the iframe
      this.frameDocument.defaultView.onerror = (message, source, lineno, colno, error) => {
        // Relay the error to the parent window
        const fullMessage = `iFrame Error: ${message} (${source}:${lineno}:${colno})`
        console.error(fullMessage, error)

        // Throw the error in the parent context for Cuprite to catch
        setTimeout(() => {
          throw new Error(fullMessage)
        }, 0)

        return false // Let the error propagate
      }

      // Set up unhandled rejection handling for the iframe
      this.frameDocument.defaultView.onunhandledrejection = (event) => {
        const fullMessage = `iFrame Unhandled Promise Rejection: ${event.reason}`
        console.error(fullMessage)

        // Throw the error in the parent context for Cuprite to catch
        setTimeout(() => {
          throw event.reason
        }, 0)
      }

      // Ensure frame is visible after load
      this.frame.style.display = ""
      this.ensureFrameVisibility()

      // Wait for document to be ready
      if (this.frameDocument.readyState !== 'complete') {
        await new Promise(resolve => {
          this.frameDocument.addEventListener('DOMContentLoaded', resolve)
        })
      }

      // Load Editor.js resources in the iframe context
      try {
        const { EDITOR_JS_RESOURCES, EDITOR_JS_CSS } = await import("panda/cms/editor/editor_js_config")
        const { ResourceLoader } = await import("panda/cms/editor/resource_loader")

        // First load EditorJS core
        const editorCore = EDITOR_JS_RESOURCES[0]
        await ResourceLoader.loadScript(this.frameDocument, this.head, editorCore)

        // Then load all tools in parallel
        const toolLoads = EDITOR_JS_RESOURCES.slice(1).map(async (resource) => {
          await ResourceLoader.loadScript(this.frameDocument, this.head, resource)
        })

        // Load CSS directly
        await ResourceLoader.embedCSS(this.frameDocument, this.head, EDITOR_JS_CSS)

        // Wait for all resources to load
        await Promise.all(toolLoads)
        console.debug("[Panda CMS] Editor resources loaded in iframe")

        // Wait a small amount of time for scripts to initialize
        await new Promise(resolve => setTimeout(resolve, 100))

        // Initialize editors only if we have the body and editable elements
        if (this.body && this.body.querySelector('[data-editable-kind]')) {
          await this.initializeEditors()
        } else {
          const error = new Error("[Panda CMS] Frame body or editable elements not found")
          console.error(error)
          throw error
        }
      } catch (error) {
        console.error("[Panda CMS] Error loading editor resources in iframe:", error)
        throw error
      }
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

  initializeEditors() {
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
      this.initializeRichTextEditors()
    }
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
      // Verify Editor.js is available in the iframe context
      if (!this.frameDocument.defaultView.EditorJS) {
        const error = new Error("Editor.js not loaded in iframe context")
        console.error("[Panda CMS]", error)
        throw error // This will bubble up and fail the test
      }

      const initializer = new EditorJSInitializer(this.frameDocument, true)

      // Don't wrap in try/catch to let errors bubble up
      const editors = await Promise.all(
        Array.from(richTextElements).map(async element => {
          // Create holder element before initialization
          const holderId = `editor-${Math.random().toString(36).substr(2, 9)}`
          const holderElement = this.frameDocument.createElement('div')
          holderElement.id = holderId
          holderElement.className = 'editor-js-holder codex-editor'
          element.appendChild(holderElement)

          // Wait for the holder element to be in the DOM
          await new Promise(resolve => setTimeout(resolve, 0))

          // Verify the holder element exists
          const verifyHolder = this.frameDocument.getElementById(holderId)
          if (!verifyHolder) {
            const error = new Error(`Failed to create editor holder element ${holderId}`)
            console.error("[Panda CMS]", error)
            throw error // This will bubble up and fail the test
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
                const error = new Error('Save failed')
                console.error("[Panda CMS]", error)
                throw error
              }

              this.handleSuccess()
            })
          } else {
            console.warn("[Panda CMS] Save button not found")
          }

          return editor
        })
      )

      // Filter out any null editors and add the valid ones
      const validEditors = editors.filter(editor => editor !== null)
      this.editors.push(...validEditors)

      // If we didn't get any valid editors, that's an error
      if (validEditors.length === 0) {
        const error = new Error("No editors were successfully initialized")
        console.error("[Panda CMS]", error)
        throw error
      }
    }

    this.editorsInitialized.rich = true
    this.checkAllEditorsInitialized()
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
}
