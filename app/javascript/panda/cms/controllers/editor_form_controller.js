import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editorContainer", "hiddenField"]
  static values = {
    editorId: String
  }

  connect() {
    this.initializeEditor()
  }

  async initializeEditor() {
    if (this.editor) return

    try {
      const holderId = this.editorIdValue || `editor-${Math.random().toString(36).substr(2, 9)}`
      let holderDiv = document.createElement('div')
      holderDiv.id = holderId
      holderDiv.className = 'codex-editor'
      this.editorContainerTarget.innerHTML = ''
      this.editorContainerTarget.appendChild(holderDiv)

      const { getEditorConfig } = await import("panda/cms/editor/editor_js_config")
      const config = getEditorConfig(holderId, this.getInitialContent())

      this.editor = new EditorJS({
        ...config,
        holder: holderId,
        autofocus: false,
        minHeight: 1,
        logLevel: 'ERROR',
        onChange: () => {
          if (!this.editor) return
          this.editor.save().then(outputData => {
            outputData.source = "editorJS"
            this.hiddenFieldTarget.value = JSON.stringify(outputData)
          })
        }
      })
    } catch (error) {
      console.error("[Panda CMS] Editor setup failed:", error)
    }
  }

  getInitialContent() {
    try {
      const value = this.hiddenFieldTarget.value
      if (value && value !== "{}") {
        const data = JSON.parse(value)
        if (data.blocks) return data
      }
    } catch (e) {
      console.warn('[Panda CMS] Could not parse initial content:', e)
    }

    return {
      time: Date.now(),
      blocks: [{ type: 'paragraph', data: { text: '' } }],
      version: "2.28.2",
      source: "editorJS"
    }
  }

  disconnect() {
    if (this.editor) {
      this.editor.destroy()
      this.editor = null
    }
  }
}
