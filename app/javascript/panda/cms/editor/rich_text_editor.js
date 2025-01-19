import EditorJS from "@editorjs/editorjs"
import Paragraph from "@editorjs/paragraph"
import Header from "@editorjs/header"
import List from "@editorjs/list"
import Quote from "@editorjs/quote"
import Table from "@editorjs/table"
import NestedList from "@editorjs/nested-list"

export default class RichTextEditor {
  constructor(element, iframe) {
    this.element = element
    this.iframe = iframe
    this.editor = null
    this.initialized = false
    this.initialize()
  }

  async initialize() {
    if (this.initialized) return
    console.debug("[Panda CMS] Initializing EditorJS")

    try {
      let content = this.element.dataset.editableContent || ""
      let previousData = this.element.dataset.editablePreviousData || ""
      console.debug("[Panda CMS] Initial content:", content)
      console.debug("[Panda CMS] Previous data:", previousData)

      let parsedContent
      if (previousData) {
        try {
          // Try to decode base64 first
          const decodedData = atob(previousData)
          console.debug("[Panda CMS] Decoded base64 data:", decodedData)
          parsedContent = JSON.parse(decodedData)
          console.debug("[Panda CMS] Successfully parsed base64 data:", parsedContent)
        } catch (e) {
          console.debug("[Panda CMS] Not base64 encoded or invalid, trying direct JSON parse:", e)
          try {
            parsedContent = JSON.parse(previousData)
            console.debug("[Panda CMS] Successfully parsed JSON data:", parsedContent)
          } catch (e2) {
            console.error("[Panda CMS] Failed to parse previous data:", e2)
            parsedContent = this.getDefaultContent()
          }
        }
      } else if (content) {
        try {
          parsedContent = JSON.parse(content)
          console.debug("[Panda CMS] Successfully parsed content:", parsedContent)
        } catch (e) {
          console.error("[Panda CMS] Failed to parse content:", e)
          parsedContent = this.getDefaultContent()
        }
      } else {
        parsedContent = this.getDefaultContent()
      }

      // Create holder element before initialization
      const holderId = `editor-${Math.random().toString(36).substr(2, 9)}`
      const holderElement = document.createElement("div")
      holderElement.id = holderId
      holderElement.className = "editor-js-holder codex-editor"

      // Clear any existing content and append holder
      this.element.textContent = ""
      this.element.appendChild(holderElement)

      // Initialize EditorJS
      this.editor = new EditorJS({
        holder: holderId,
        data: parsedContent,
        placeholder: "Click to start writing...",
        tools: {
          paragraph: {
            class: Paragraph,
            inlineToolbar: true
          },
          header: {
            class: Header,
            inlineToolbar: true
          },
          list: {
            class: NestedList,
            inlineToolbar: true,
            config: {
              defaultStyle: 'unordered',
              enableLineBreaks: true
            }
          },
          quote: {
            class: Quote,
            inlineToolbar: true
          },
          table: {
            class: Table,
            inlineToolbar: true
          }
        },
        onChange: () => {
          this.save()
        }
      })

      await this.editor.isReady
      this.initialized = true
      console.debug("[Panda CMS] EditorJS initialized successfully")
    } catch (error) {
      console.error("[Panda CMS] Error initializing EditorJS:", error)
    }
  }

  getDefaultContent() {
    return {
      time: Date.now(),
      blocks: [
        {
          type: "paragraph",
          data: {
            text: ""
          }
        }
      ],
      version: "2.28.2"
    }
  }

  async save() {
    if (!this.editor) return null

    try {
      const savedData = await this.editor.save()
      const jsonString = JSON.stringify(savedData)
      // Store both base64 and regular JSON
      this.element.dataset.editablePreviousData = btoa(jsonString)
      this.element.dataset.editableContent = jsonString
      return jsonString
    } catch (error) {
      console.error("[Panda CMS] Error saving EditorJS content:", error)
      return null
    }
  }

  async clear() {
    if (!this.editor) return

    try {
      await this.editor.clear()
      this.element.dataset.editablePreviousData = ""
      this.element.dataset.editableContent = ""
    } catch (error) {
      console.error("[Panda CMS] Error clearing EditorJS content:", error)
    }
  }

  destroy() {
    if (this.editor) {
      this.editor.destroy()
      this.editor = null
      this.initialized = false
    }
  }
}
