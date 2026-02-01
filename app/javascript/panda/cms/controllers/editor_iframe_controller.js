import { Controller } from "@hotwired/stimulus"
import { PlainTextEditor } from "panda/editor/plain_text_editor"
import { EditorJSInitializer } from "panda/editor/editor_js_initializer"
import { EDITOR_JS_RESOURCES, EDITOR_JS_CSS } from "panda/editor/editor_js_config"
import { ResourceLoader } from "panda/editor/resource_loader"

// UTF-8 safe Base64 helpers — atob/btoa only handle Latin-1, corrupting multi-byte characters
function base64Decode(base64) {
  const binaryString = atob(base64);
  const bytes = Uint8Array.from(binaryString, (c) => c.charCodeAt(0));
  return new TextDecoder("utf-8").decode(bytes);
}

function base64Encode(str) {
  const bytes = new TextEncoder().encode(str);
  const binaryString = Array.from(bytes, (b) => String.fromCharCode(b)).join("");
  return btoa(binaryString);
}

export default class extends Controller {
  static values = {
    pageId: Number,
    adminPath: String,
    autosave: Boolean,
    assets: String
  }

  connect() {
    console.debug("[Panda CMS] EditorIframe controller connected")
    this.frame = this.element
    this.logLayoutState("connect() start")
    this.setupControls()
    this.logLayoutState("after setupControls()")
    this.setupFrame()
    this.logLayoutState("after setupFrame()")
    this.editors = []
    this.editorsInitialized = {
      plain: false,
      rich: false
    }
    this.setupSlideoverHandling()
    this.logLayoutState("after setupSlideoverHandling()")
    this.setupEditorInitializationListener()
  }

  // Debug helper to log layout state
  logLayoutState(label) {
    // Use multiple strategies to find sidebar
    const pandaContainer = document.getElementById('panda-container')
    const sidebar = pandaContainer?.firstElementChild
    const mainContent = document.getElementById('panda-inner-container')
    const primaryContent = document.getElementById('panda-primary-content')

    const state = {
      viewportWidth: window.innerWidth,
      viewportHeight: window.innerHeight,
      sidebarFound: !!sidebar,
      sidebarDisplay: sidebar ? getComputedStyle(sidebar).display : 'not found',
      sidebarPosition: sidebar ? getComputedStyle(sidebar).position : 'not found',
      sidebarWidth: sidebar ? getComputedStyle(sidebar).width : 'not found',
      sidebarLeft: sidebar ? getComputedStyle(sidebar).left : 'not found',
      mainMarginLeft: mainContent ? getComputedStyle(mainContent).marginLeft : 'not found',
      mainWidth: mainContent ? getComputedStyle(mainContent).width : 'not found',
      primaryContentWidth: primaryContent ? getComputedStyle(primaryContent).width : 'not found',
      frameWidth: this.frame ? getComputedStyle(this.frame).width : 'not found',
      framePosition: this.frame ? getComputedStyle(this.frame).position : 'not found',
      frameZIndex: this.frame?.style.zIndex || 'not set',
      documentScrollWidth: document.documentElement.scrollWidth,
      bodyScrollWidth: document.body?.scrollWidth
    }

    console.debug(`[Layout Debug] ${label}:`, state)

    // Alert if margin changes from expected value
    if (mainContent && window.innerWidth >= 1024) {
      const marginLeft = parseFloat(getComputedStyle(mainContent).marginLeft)
      if (marginLeft < 280) { // Expected ~288px (18rem)
        console.error(`[Layout SHIFT DETECTED] ${label}: mainMarginLeft is ${marginLeft}px (expected ~288px)`)
      }
    }
  }

  setupControls() {
    // The save button should already exist in the page header (created by ERB template)
    // Only create fallback controls if the save button doesn't exist
    if (!parent.document.getElementById('saveEditableButton')) {
      // Create editor controls container if needed (hidden by default to prevent layout shift)
      if (!parent.document.querySelector('.editor-controls')) {
        const controls = parent.document.createElement('div')
        controls.className = 'editor-controls'
        // Position absolutely to prevent layout shift
        controls.style.cssText = 'position: fixed; top: 10px; right: 10px; z-index: 9999;'
        parent.document.body.appendChild(controls)
      }

      const saveButton = parent.document.createElement('a')
      saveButton.id = 'saveEditableButton'
      saveButton.href = '#'
      saveButton.textContent = 'Save Changes'
      saveButton.className = 'btn btn-primary'
      parent.document.querySelector('.editor-controls').appendChild(saveButton)
    }
  }

  setupFrame() {
    // Styles are set in the ERB template - avoid modifying them to prevent reflow
    // Get CSRF token
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ""

    // Handler for when frame is loaded (with guard against double initialization)
    this.frameInitialized = false
    const handleFrameLoad = async () => {
      if (this.frameInitialized) {
        console.debug("[Panda CMS] Frame already initialized, skipping")
        return
      }
      this.frameInitialized = true
      this.logLayoutState("handleFrameLoad start")

      this.frameDocument = this.frame.contentDocument || this.frame.contentWindow.document
      this.body = this.frameDocument.body
      this.head = this.frameDocument.head

      // NOTE: We intentionally do NOT inject CMS assets into the iframe.
      // Reasons:
      // 1. The iframe loads the frontend page which has its own complete CSS styling
      // 2. EditorJS resources are loaded separately via loadEditorResources()
      // 3. Injecting admin CSS (panda-core) would conflict with the site's styling
      //    (causes "black everywhere" due to CSS variable conflicts and global style overrides)
      // 4. All editor initialization happens from the parent window via this controller
      console.debug("[Panda CMS] Skipping asset injection (not needed, would conflict with site CSS)")

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
    }

    // Setup frame load handler for future loads
    this.frame.addEventListener("load", handleFrameLoad)

    // Check if iframe is already loaded (timing issue: controller may connect after load event)
    // An iframe is considered loaded if it has contentDocument with a body AND the correct URL
    // Important: We must verify the URL because about:blank also has readyState='complete'
    try {
      const doc = this.frame.contentDocument || this.frame.contentWindow?.document
      const expectedSrc = this.frame.src
      const actualUrl = doc?.location?.href || ''

      // Only initialize if the actual document URL matches the expected source
      // (not about:blank or any other intermediate state)
      const isCorrectDocument = actualUrl && actualUrl !== 'about:blank' &&
        (actualUrl === expectedSrc || actualUrl.includes('embed_id='))

      if (doc && doc.body && doc.readyState === 'complete' && isCorrectDocument) {
        console.debug("[Panda CMS] Frame already loaded with correct URL, initializing immediately", { expectedSrc, actualUrl })
        handleFrameLoad()
      } else {
        console.debug("[Panda CMS] Waiting for frame load event", { expectedSrc, actualUrl, readyState: doc?.readyState })
      }
    } catch (e) {
      // Cross-origin or other access error - wait for load event
      console.debug("[Panda CMS] Cannot access frame document yet, waiting for load event")
    }
  }

  ensureFrameVisibility() {
    console.debug("[Panda CMS] ensureFrameVisibility called")
    this.logLayoutState("ensureFrameVisibility - before any changes")

    // Force frame to be visible
    this.frame.style.display = ""
    this.logLayoutState("ensureFrameVisibility - after display=''")

    // Check dimensions and fix if needed
    const beforeWidth = this.frame.offsetWidth
    const beforeHeight = this.frame.offsetHeight
    console.debug("[Panda CMS] Frame dimensions before fix:", { beforeWidth, beforeHeight })

    if (beforeWidth === 0 || beforeHeight === 0) {
      console.warn("[Panda CMS] iFrame has zero dimensions, fixing...")
      this.frame.style.width = "100%"
      this.frame.style.height = "100%"
      this.frame.style.minHeight = "500px"
      this.logLayoutState("ensureFrameVisibility - after dimension fix")
    }

    // Log visibility state
    console.debug("[Panda CMS] Frame visibility state:", {
      display: this.frame.style.display,
      width: this.frame.offsetWidth,
      height: this.frame.offsetHeight,
      visible: this.frame.offsetParent !== null
    })
  }

  setupEditorInitializationListener() {
    // Listen for the custom event to initialize editors
    this.frame.addEventListener("load", () => {
      const win = this.frame.contentWindow || this.frame.contentDocument.defaultView
      win.addEventListener('panda-cms:initialize-editors', async () => {
        console.debug("[Panda CMS] Received initialize-editors event")
        await this.initializeEditors()
      })
    })
  }

  async initializeEditors() {
    console.debug("[Panda CMS] Starting editor initialization")
    this.logLayoutState("initializeEditors start")

    // Get all editable elements
    const plainTextElements = this.body.querySelectorAll('[data-editable-kind="plain_text"], [data-editable-kind="markdown"], [data-editable-kind="html"]')
    const richTextElements = this.body.querySelectorAll('[data-editable-kind="rich_text"]')

    console.debug(`[Panda CMS] Found ${plainTextElements.length} plain text elements and ${richTextElements.length} rich text elements`)

    // Always ensure frame is visible
    this.ensureFrameVisibility()
    this.logLayoutState("after ensureFrameVisibility")

    // Initialize editors if they exist
    if (plainTextElements.length > 0 || richTextElements.length > 0) {
      try {
        // Load resources first
        await this.loadEditorResources()
        this.logLayoutState("after loadEditorResources")

        // Initialize editors
        await Promise.all([
          this.initializePlainTextEditors(),
          this.initializeRichTextEditors()
        ])

        console.debug("[Panda CMS] All editors initialized successfully")
        this.logLayoutState("after all editors initialized")
      } catch (error) {
        console.error("[Panda CMS] Error initializing editors:", error)
        throw error
      }
    }
  }

  async loadEditorResources() {
    console.debug("[Panda CMS] Loading editor resources in iframe...")
    try {
      // First load core EditorJS
      await ResourceLoader.loadScript(this.frameDocument, this.frameDocument.head, EDITOR_JS_RESOURCES[0])

      // Wait for EditorJS to be available with increased timeout
      let timeout = 10000 // 10 seconds
      const start = Date.now()

      while (Date.now() - start < timeout) {
        if (this.frameDocument.defaultView.EditorJS) {
          console.debug("[Panda CMS] EditorJS core loaded successfully")
          break
        }
        await new Promise(resolve => setTimeout(resolve, 100))
      }

      if (!this.frameDocument.defaultView.EditorJS) {
        throw new Error("Timeout waiting for EditorJS core to load")
      }

      // Load CSS
      await ResourceLoader.embedCSS(this.frameDocument, this.frameDocument.head, EDITOR_JS_CSS)

      // Then load all tools sequentially
      for (const resource of EDITOR_JS_RESOURCES.slice(1)) {
        await ResourceLoader.loadScript(this.frameDocument, this.frameDocument.head, resource)
      }

      console.debug("[Panda CMS] All editor resources loaded successfully")
    } catch (error) {
      console.error("[Panda CMS] Error loading editor resources:", error)
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
            // Skip already initialized editors
            if (element.dataset.editableInitialized === 'true' && element.querySelector('.codex-editor')) {
              console.debug('[Panda CMS] Editor already initialized:', element.id)
              continue
            }

            console.debug('[Panda CMS] Initializing editor for element:', {
              id: element.id,
              kind: element.getAttribute('data-editable-kind'),
              blockContentId: element.getAttribute('data-editable-block-content-id')
            })

            // Create holder element before initialization
            const holderId = `editor-${Math.random().toString(36).substr(2, 9)}`
            const holderElement = this.frameDocument.createElement('div')
            holderElement.id = holderId
            holderElement.className = 'editor-js-holder codex-editor'

            // Clear any existing content
            element.textContent = ''
            element.appendChild(holderElement)

            // Get previous data from the data attribute if available
            let previousData = { blocks: [] }
            const previousDataAttr = element.getAttribute('data-editable-previous-data')
            if (previousDataAttr) {
              try {
                let parsedData
                try {
                  // First try to parse as base64
                  const decodedData = base64Decode(previousDataAttr)
                  console.debug('[Panda CMS] Decoded base64 data:', decodedData)
                  parsedData = JSON.parse(decodedData)
                } catch (e) {
                  // If base64 fails, try direct JSON parse
                  console.debug('[Panda CMS] Trying direct JSON parse')
                  parsedData = JSON.parse(previousDataAttr)
                }

                // Check if we have double-encoded data
                if (parsedData.blocks?.length === 1 &&
                  parsedData.blocks[0]?.type === 'paragraph' &&
                  parsedData.blocks[0]?.data?.text) {
                  try {
                    // Try to parse the inner JSON
                    const innerData = JSON.parse(parsedData.blocks[0].data.text)
                    if (innerData.blocks) {
                      console.debug('[Panda CMS] Found double-encoded data, using inner content:', innerData)
                      parsedData = innerData
                    }
                  } catch (e) {
                    // If parsing fails, use the outer data
                    console.debug('[Panda CMS] Not double-encoded data, using as is')
                  }
                }

                if (parsedData && typeof parsedData === 'object' && Array.isArray(parsedData.blocks)) {
                  previousData = parsedData
                  console.debug('[Panda CMS] Using previous data:', previousData)
                } else {
                  console.warn('[Panda CMS] Invalid data format:', parsedData)
                }
              } catch (error) {
                console.error("[Panda CMS] Error parsing previous data:", error)
                // If we can't parse the data, try to use it as plain text
                previousData = {
                  time: Date.now(),
                  blocks: [
                    {
                      type: "paragraph",
                      data: {
                        text: element.textContent || ""
                      }
                    }
                  ],
                  version: "2.28.2"
                }
              }
            }

            // Initialize editor with retry logic
            let editor = null
            let retryCount = 0
            const maxRetries = 3

            while (!editor && retryCount < maxRetries) {
              try {
                console.debug(`[Panda CMS] Editor initialization attempt ${retryCount + 1}`)
                editor = await initializer.initialize(holderElement, previousData, holderId)
                console.debug('[Panda CMS] Editor initialized successfully:', editor)

                // Set up autosave if enabled
                if (this.autosaveValue) {
                  editor.isReady.then(() => {
                    editor.save().then((outputData) => {
                      const jsonString = JSON.stringify(outputData)
                      element.dataset.editablePreviousData = base64Encode(jsonString)
                      element.dataset.editableContent = jsonString
                      element.dataset.editableInitialized = 'true'
                    })
                  })
                }

                break
              } catch (error) {
                console.warn(`[Panda CMS] Editor initialization attempt ${retryCount + 1} failed:`, error)
                retryCount++
                if (retryCount === maxRetries) {
                  throw error
                }
                // Wait before retrying
                await new Promise(resolve => setTimeout(resolve, 1000))
              }
            }

            // Set up save handler for this editor
            const saveButton = parent.document.getElementById('saveEditableButton')
            if (saveButton) {
              saveButton.addEventListener('click', async () => {
                try {
                  const outputData = await editor.save()
                  console.debug('[Panda CMS] Editor save data:', outputData)

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

                  // Update the data attributes with the new content
                  const jsonString = JSON.stringify(outputData)
                  element.dataset.editablePreviousData = base64Encode(jsonString)
                  element.dataset.editableContent = jsonString
                  element.dataset.editableInitialized = 'true'

                  this.handleSuccess()
                } catch (error) {
                  console.error("[Panda CMS] Save error:", error)
                  this.handleError(error)
                }
              })
            } else {
              console.warn("[Panda CMS] Save button not found")
            }

            if (editor) {
              editors.push(editor)
            }
          } catch (error) {
            console.error("[Panda CMS] Editor initialization error:", error)
            throw error
          }
        }

        // Filter out any null editors and add the valid ones
        const validEditors = editors.filter(editor => editor !== null)
        this.editors.push(...validEditors)

        // If we didn't get any valid editors, that's an error
        if (validEditors.length === 0 && richTextElements.length > 0) {
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
    console.debug("[Panda CMS] Editor initialization status:", this.editorsInitialized)

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
    // Watch for slideover visibility changes
    const slideover = document.getElementById('slideover')

    if (slideover) {
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
    this.logLayoutState(`adjustFrameZIndex - before (slideoverVisible=${slideoverVisible})`)
    if (slideoverVisible) {
      // Lower z-index when slideover is visible
      this.frame.style.zIndex = "0"
      if (this.body) this.body.style.zIndex = "0"
    } else {
      // Restore z-index when slideover is hidden
      this.frame.style.zIndex = "1"
      if (this.body) this.body.style.zIndex = "1"
    }
    this.logLayoutState(`adjustFrameZIndex - after (slideoverVisible=${slideoverVisible})`)
    console.debug("[Panda CMS] Adjusted frame z-index:", {
      slideoverVisible,
      frameZIndex: this.frame.style.zIndex,
      bodyZIndex: this.body?.style.zIndex
    })
  }
}
