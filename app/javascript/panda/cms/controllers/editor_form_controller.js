import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editorContainer", "hiddenField"]
  static values = {
    editorId: String
  }

  connect() {
    console.debug("[Panda CMS] Editor form controller connected")
    this.editorInitialized = false
    this.initializeEditor()
  }

  async initializeEditor() {
    if (this.editorInitialized) {
      console.debug("[Panda CMS] Editor already initialized")
      return
    }

    try {
      // Create editor container if needed
      const holderId = this.editorIdValue ? `editor_${this.editorIdValue}_holder` : `editor-${Math.random().toString(36).substr(2, 9)}_holder`
      let holderDiv = this.editorContainerTarget.querySelector(`#${holderId}`)
      if (!holderDiv) {
        holderDiv = document.createElement('div')
        holderDiv.id = holderId
        holderDiv.className = 'codex-editor'
        // Clear any existing content in this container
        this.editorContainerTarget.innerHTML = ''
        this.editorContainerTarget.appendChild(holderDiv)
      }

      // Get initial content and editor config in parallel
      const [initialData, { getEditorConfig }] = await Promise.all([
        Promise.resolve(this.getInitialContent()),
        import("panda/cms/editor/editor_js_config")
      ])

      console.debug("[Panda CMS] Initial data:", initialData)

      // Quick check for required tools before full wait
      const hasTools = window.EditorJS && window.Header && window.Paragraph
      if (!hasTools) {
        await this.waitForEditorTools()
      }

      // Initialize new editor with optimized config
      console.debug("[Panda CMS] Creating new editor instance...")
      const config = getEditorConfig(holderId, initialData)

      // Create editor instance with optimized settings
      const editor = new EditorJS({
        ...config,
        holder: holderId,
        autofocus: false, // Disable autofocus for faster initialization
        minHeight: 1, // Minimum height to prevent layout shifts
        logLevel: 'ERROR', // Reduce logging overhead
        onReady: () => {
          console.debug("[Panda CMS] Editor ready")
          this.editor = editor
          editor.isReady = true
          this.editorInitialized = true

          // Set up event listeners and force redraw in parallel
          Promise.all([
            Promise.resolve(this.setupEventListeners()),
            this.forceRedrawIfNeeded(editor)
          ]).catch(console.error)
        },
        onChange: async (api, event) => {
          if (!this.editor?.isReady) return // Skip if editor isn't ready

          try {
            const outputData = await api.saver.save()
            outputData.source = "editorJS"
            const contentJson = JSON.stringify(outputData)

            // Batch DOM updates
            requestAnimationFrame(() => {
              this.hiddenFieldTarget.value = contentJson
              this.hiddenFieldTarget.dataset.initialContent = contentJson
              this.hiddenFieldTarget.dispatchEvent(new Event('change', { bubbles: true }))
            })
          } catch (error) {
            console.error("[Panda CMS] Error saving editor content:", error)
          }
        }
      })

      // Store editor instance
      this.editorContainerTarget.editorInstance = editor

      // Wait for editor with reduced timeout in test environment
      const timeout = process.env.NODE_ENV === 'test' ? 5000 : 30000
      await Promise.race([
        new Promise((_, reject) => setTimeout(() => reject(new Error('Editor initialization timed out')), timeout)),
        new Promise(resolve => {
          const checkReady = () => {
            if (editor.isReady) resolve()
            else requestAnimationFrame(checkReady)
          }
          checkReady()
        })
      ])

      console.debug("[Panda CMS] Editor initialization complete")
    } catch (error) {
      console.error("[Panda CMS] Error during editor setup:", error)
      this.editorInitialized = false
      throw error // Let the error propagate in test environment
    }
  }

  async forceRedrawIfNeeded(editor) {
    const toolbar = this.editorContainerTarget.querySelector('.ce-toolbar')
    const blockWrapper = this.editorContainerTarget.querySelector('.ce-block__content')

    if (!toolbar || !blockWrapper) {
      console.warn("[Panda CMS] Editor UI components not found, forcing redraw...")
      await editor.blocks.clear()
      await editor.blocks.insert('paragraph')

      // Force reflow
      void this.editorContainerTarget.offsetHeight
    }
  }

  async waitForEditorTools() {
    const requiredTools = ['Header', 'Paragraph']
    const maxAttempts = process.env.NODE_ENV === 'test' ? 50 : 300 // Reduced attempts in test environment
    const interval = process.env.NODE_ENV === 'test' ? 50 : 100 // Faster polling in test environment

    for (let attempts = 0; attempts < maxAttempts; attempts++) {
      const missingTools = requiredTools.filter(tool => !window[tool] || typeof window[tool] !== 'function')

      if (missingTools.length === 0) {
        console.debug("[Panda CMS] Required editor tools are available")
        return
      }

      if (attempts % 10 === 0) { // Log less frequently
        console.debug(`[Panda CMS] Waiting for tools: ${missingTools.join(', ')} (attempt ${attempts + 1}/${maxAttempts})`)
      }

      await new Promise(resolve => setTimeout(resolve, interval))
    }

    throw new Error('Required editor tools failed to load')
  }

  getInitialContent() {
    try {
      // First try to get content from the data-initial-content attribute
      const initialContent = this.hiddenFieldTarget.dataset.initialContent
      if (initialContent && initialContent !== "{}") {
        try {
          const data = JSON.parse(initialContent)
          if (data.blocks) return data
        } catch (e) {
          console.warn('[Panda CMS] Could not parse initial content as JSON:', e)
        }
      }

      // Then try the input value
      const value = this.hiddenFieldTarget.value
      if (value && value !== "{}") {
        try {
          const data = JSON.parse(value)
          if (data.blocks) return data
        } catch (e) {
          console.warn('[Panda CMS] Could not parse input value as JSON:', e)
        }
      }
    } catch (e) {
      console.warn('[Panda CMS] Error getting initial content:', e)
    }

    // Return empty editor data if nothing else works
    return {
      time: Date.now(),
      blocks: [{
        type: 'paragraph',
        data: {
          text: ''
        }
      }],
      version: "2.28.2",
      source: "editorJS"
    }
  }

  setupEventListeners() {
    // Save content on blur
    this.editorContainerTarget.addEventListener('blur', () => {
      this.saveContent()
    }, true)

    // Autosave periodically
    this.autosaveInterval = setInterval(() => {
      this.saveContent()
    }, 5000)
  }

  async saveContent() {
    if (!this.editor || !this.editor.isReady) return

    try {
      const outputData = await this.editor.save()
      outputData.source = "editorJS"
      const contentJson = JSON.stringify(outputData)
      this.hiddenFieldTarget.value = contentJson
      this.hiddenFieldTarget.dataset.initialContent = contentJson
      this.hiddenFieldTarget.dispatchEvent(new Event('change', { bubbles: true }))
    } catch (error) {
      console.error("[Panda CMS] Error saving editor content:", error)
    }
  }

  handleContentChange() {
    this.saveContent()
  }

  submit(event) {
    if (this.editor && this.editor.isReady) {
      this.saveContent()
    }
  }

  disconnect() {
    if (this.autosaveInterval) {
      clearInterval(this.autosaveInterval)
    }
  }
}
