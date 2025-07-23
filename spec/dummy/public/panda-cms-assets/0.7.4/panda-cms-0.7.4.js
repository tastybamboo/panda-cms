// Panda CMS JavaScript Bundle v0.7.4
// Compiled: 2025-07-20T18:24:58Z

// Stimulus Application Setup
import { Application } from '@hotwired/stimulus';
const pandaCmsApplication = Application.start();
pandaCmsApplication.debug = false; // Set to true for debugging

// dashboard_controller
class DashboardControllerController extends Controller {
  connect() {
  }
}


// Register controller
pandaCmsApplication.register('dashboard', DashboardControllerController);

// editor_form_controller
class EditorFormControllerController extends Controller {
  static targets = ["editorContainer", "hiddenField"];
  static values = {
    editorId: String,
  };

  connect() {
    this.loadEditorResources();
  }

  async loadEditorResources() {
    try {
      // First load EditorJS core
      const editorCore = EDITOR_JS_RESOURCES[0];
      await ResourceLoader.loadScript(document, document.head, editorCore);

      // Load CSS
      await ResourceLoader.embedCSS(document, document.head, EDITOR_JS_CSS);

      // Then load all tools sequentially
      for (const resource of EDITOR_JS_RESOURCES.slice(1)) {
        await ResourceLoader.loadScript(document, document.head, resource);
      }

      await this.initializeEditor();
    } catch (error) {
      console.error("[Panda CMS] Failed to load editor resources:", error);
    }
  }

  async initializeEditor() {
    if (this.editor) return;

    try {
      const holderId =
        this.editorIdValue + "_holder" ||
        `editor-${Math.random().toString(36).substring(2, 9)}`;
      let holderDiv = document.createElement("div");
      holderDiv.id = holderId;
      holderDiv.className = "codex-editor";
      this.editorContainerTarget.innerHTML = "";
      this.editorContainerTarget.appendChild(holderDiv);

      const { getEditorConfig } = await import(
        "panda/cms/editor/editor_js_config"
      );

      // Get initial content before creating config
      const initialContent = this.getInitialContent();
      console.debug("[Panda CMS] Using initial content:", initialContent);

      const config = {
        ...getEditorConfig(holderId, initialContent),
        holder: holderId,
        data: initialContent,
        autofocus: false,
        minHeight: 1,
        logLevel: "ERROR",
        onChange: () => {
          if (!this.editor) return;
          this.editor.save().then((outputData) => {
            outputData.source = "editorJS";
            const jsonString = JSON.stringify(outputData);
            // Store both base64 and regular JSON
            this.editorContainerTarget.dataset.editablePreviousData = btoa(jsonString);
            this.editorContainerTarget.dataset.editableContent = jsonString;
            this.hiddenFieldTarget.value = jsonString;
          });
        },
        onReady: () => {
          console.debug("[Panda CMS] Editor ready with content:", initialContent);
          this.editorContainerTarget.dataset.editorInitialized = "true";
          holderDiv.dataset.editorInitialized = "true";
          // Add a class to indicate the editor is ready
          holderDiv.classList.add("editor-ready");
          // Dispatch an event when editor is ready
          this.editorContainerTarget.dispatchEvent(new CustomEvent("editor:ready"));
        },
        tools: {
          paragraph: {
            class: window.Paragraph,
            inlineToolbar: true
          },
          header: {
            class: window.Header,
            inlineToolbar: true
          },
          list: {
            class: window.NestedList,
            inlineToolbar: true,
            config: {
              defaultStyle: 'unordered',
              enableLineBreaks: true
            }
          },
          quote: {
            class: window.Quote,
            inlineToolbar: true
          },
          table: {
            class: window.Table,
            inlineToolbar: true
          }
        }
      };

      // Ensure EditorJS is available
      const EditorJS = window.EditorJS;
      if (!EditorJS) {
        throw new Error("EditorJS not loaded");
      }

      this.editor = new EditorJS(config);

      // Wait for editor to be ready
      await this.editor.isReady;
      console.debug("[Panda CMS] Editor initialized successfully");
      this.editorContainerTarget.dataset.editorInitialized = "true";
      holderDiv.dataset.editorInitialized = "true";
      // Add a class to indicate the editor is ready
      holderDiv.classList.add("editor-ready");
      // Dispatch an event when editor is ready
      this.editorContainerTarget.dispatchEvent(new CustomEvent("editor:ready"));

    } catch (error) {
      console.error("[Panda CMS] Editor setup failed:", error);
      this.editorContainerTarget.dataset.editorInitialized = "false";
      if (holderDiv) {
        holderDiv.dataset.editorInitialized = "false";
        holderDiv.classList.remove("editor-ready");
      }
    }
  }

  getInitialContent() {
    try {
      const initialContent = this.hiddenFieldTarget.getAttribute("data-initial-content");
      if (initialContent && initialContent !== "{}") {
        try {
          // First try to decode as base64
          try {
            const decodedData = atob(initialContent);
            const data = JSON.parse(decodedData);
            if (data.blocks) return data;
          } catch (e) {
            // If base64 decode fails, try direct JSON parse
            const data = JSON.parse(initialContent);
            if (data.blocks) return data;
          }
        } catch (e) {
          console.error("[Panda CMS] Failed to parse content:", e);
        }
      }

      // Try to get content from the editor container's data attributes
      const previousData = this.editorContainerTarget.dataset.editablePreviousData;
      const editorContent = this.editorContainerTarget.dataset.editableContent;

      if (previousData) {
        try {
          const decodedData = atob(previousData);
          const data = JSON.parse(decodedData);
          if (data.blocks) return data;
        } catch (e) {
          console.debug("[Panda CMS] Failed to parse base64 data:", e);
        }
      }

      if (editorContent && editorContent !== "{}") {
        try {
          const data = JSON.parse(editorContent);
          if (data.blocks) return data;
        } catch (e) {
          console.debug("[Panda CMS] Failed to parse editor content:", e);
        }
      }
    } catch (e) {
      console.warn("[Panda CMS] Could not parse initial content:", e);
    }

    // Return default content if nothing else works
    return {
      time: Date.now(),
      blocks: [{ type: "paragraph", data: { text: "" } }],
      version: "2.28.2",
      source: "editorJS",
    };
  }

  disconnect() {
    if (this.editor) {
      this.editor.destroy();
      this.editor = null;
    }
  }
}


// Register controller
pandaCmsApplication.register('editor-form', EditorFormControllerController);

// editor_iframe_controller
class EditorIframeControllerController extends Controller {
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
    this.setupEditorInitializationListener()
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

    // Get all editable elements
    const plainTextElements = this.body.querySelectorAll('[data-editable-kind="plain_text"], [data-editable-kind="markdown"], [data-editable-kind="html"]')
    const richTextElements = this.body.querySelectorAll('[data-editable-kind="rich_text"]')

    console.debug(`[Panda CMS] Found ${plainTextElements.length} plain text elements and ${richTextElements.length} rich text elements`)

    // Always ensure frame is visible
    this.ensureFrameVisibility()

    // Initialize editors if they exist
    if (plainTextElements.length > 0 || richTextElements.length > 0) {
      try {
        // Load resources first
        await this.loadEditorResources()

        // Initialize editors
        await Promise.all([
          this.initializePlainTextEditors(),
          this.initializeRichTextEditors()
        ])

        console.debug("[Panda CMS] All editors initialized successfully")
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
                  const decodedData = atob(previousDataAttr)
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
                      element.dataset.editablePreviousData = btoa(jsonString)
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
                  element.dataset.editablePreviousData = btoa(jsonString)
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


// Register controller
pandaCmsApplication.register('editor-iframe', EditorIframeControllerController);

// slug_controller
class SlugControllerController extends Controller {
  static targets = [
    "existing_root",
    "input_select",
    "input_text",
    "output_text",
  ];

  static values = {
    addDatePrefix: { type: Boolean, default: false }
  }

  connect() {
    console.debug("[Panda CMS] Slug handler connected...");
    // Don't auto-generate on connect anymore
  }

  generatePath(event) {
    // Prevent event object from being used as input
    const title = this.input_textTarget.value.trim();
    console.debug("[Panda CMS] Generating path from title:", title);

    if (!title) {
      this.output_textTarget.value = "";
      return;
    }

    // Only generate path if output is empty OR user has not manually edited it
    if (!this.output_textTarget.value || !this.output_textTarget.dataset.userEdited) {
      // Convert title to slug format
      const slug = this.createSlug(title);
      console.debug("[Panda CMS] Generated slug:", slug);

      // Only add year/month prefix for posts
      if (this.addDatePrefixValue) {
        // Get current date for year/month
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, "0");

        // Add leading slash and use date format
        this.output_textTarget.value = `/${year}/${month}/${slug}`;
      } else {
        // If we have a parent selected, let setPrePath handle it
        if (this.input_selectTarget.value) {
          this.setPrePath(slug);
        } else {
          // Add leading slash for regular pages
          this.output_textTarget.value = `/${slug}`;
        }
      }
      console.debug("[Panda CMS] Final path value:", this.output_textTarget.value);
    }
  }

  setPrePath(slug = null) {
    try {
      // Don't do anything if we're passed the event object
      if (slug && typeof slug === 'object') {
        slug = null;
      }

      const match = this.input_selectTarget.options[this.input_selectTarget.selectedIndex].text.match(/.*\((.*)\)$/);
      if (match) {
        const parentPath = match[1].replace(/\/$/, ""); // Remove trailing slash if present

        // If we have a specific slug passed in, use it
        // Otherwise only use the title-based slug if we have a title
        const currentSlug = slug ||
          (this.input_textTarget.value.trim() ? this.createSlug(this.input_textTarget.value.trim()) : "");

        // Set the full path including parent path
        this.output_textTarget.value = currentSlug
          ? `${parentPath}/${currentSlug}`
          : `${parentPath}/`;

        console.debug("[Panda CMS] Set path with parent:", this.output_textTarget.value);
      }
    } catch (e) {
      console.error("[Panda CMS] Error setting pre-path:", e);
      // Clear the output on error
      this.output_textTarget.value = "";
    }
  }

  createSlug(input) {
    if (!input || typeof input !== 'string') return "";
    const slug = input
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");
    return slug;
  }

  trimStartEnd(str, ch) {
    let start = 0,
      end = str.length;
    while (start < end && str[start] === ch) ++start;
    while (end > start && str[end - 1] === ch) --end;
    return start > 0 || end < str.length ? str.substring(start, end) : str;
  }

  // Add handler for manual path edits
  handlePathInput() {
    this.output_textTarget.dataset.userEdited = "true";
  }
}


// Register controller
pandaCmsApplication.register('slug', SlugControllerController);

// theme_form_controller
// Connects to data-controller="theme-form"
class ThemeFormControllerController extends Controller {
  updateTheme(event) {
    const newTheme = event.target.value;
    document.documentElement.dataset.theme = newTheme;
  }
}


// Register controller
pandaCmsApplication.register('theme-form', ThemeFormControllerController);

// TailwindCSS Stimulus Components (placeholder for CDN loading)
// These will be loaded from CDN in the browser

// Export application for global access
window.pandaCmsStimulus = pandaCmsApplication;