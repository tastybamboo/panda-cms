import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["previewTab", "codeTab", "previewView", "codeView", "codeInput", "saveMessage"]
  static values = {
    pageId: String,
    blockContentId: String
  }

  connect() {
    // Preview is active by default
  }

  showPreview(event) {
    event.preventDefault()

    // Toggle tabs
    this.previewTabTarget.classList.remove("border-transparent", "text-gray-500", "hover:border-gray-300", "hover:text-gray-700")
    this.previewTabTarget.classList.add("border-primary", "text-primary")

    this.codeTabTarget.classList.remove("border-primary", "text-primary")
    this.codeTabTarget.classList.add("border-transparent", "text-gray-500", "hover:border-gray-300", "hover:text-gray-700")

    // Toggle views
    this.previewViewTarget.classList.remove("hidden")
    this.codeViewTarget.classList.add("hidden")
  }

  showCode(event) {
    event.preventDefault()

    // Toggle tabs
    this.codeTabTarget.classList.remove("border-transparent", "text-gray-500", "hover:border-gray-300", "hover:text-gray-700")
    this.codeTabTarget.classList.add("border-primary", "text-primary")

    this.previewTabTarget.classList.remove("border-primary", "text-primary")
    this.previewTabTarget.classList.add("border-transparent", "text-gray-500", "hover:border-gray-300", "hover:text-gray-700")

    // Toggle views
    this.codeViewTarget.classList.remove("hidden")
    this.previewViewTarget.classList.add("hidden")
  }

  async saveCode(event) {
    event.preventDefault()

    const code = this.codeInputTarget.value
    const pageId = this.pageIdValue
    const blockContentId = this.blockContentIdValue

    try {
      const response = await fetch(`/admin/cms/pages/${pageId}/block_contents/${blockContentId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          content: code
        })
      })

      if (response.ok) {
        this.showSaveMessage('Code saved successfully!', 'success')

        // Reload the page to show updated preview
        setTimeout(() => {
          window.location.reload()
        }, 1000)
      } else {
        this.showSaveMessage('Error saving code', 'error')
      }
    } catch (error) {
      console.error('Error saving code:', error)
      this.showSaveMessage('Error saving code', 'error')
    }
  }

  showSaveMessage(message, type) {
    const messageEl = this.saveMessageTarget
    messageEl.textContent = message
    messageEl.classList.remove('hidden')

    if (type === 'success') {
      messageEl.className = 'mt-2 p-3 rounded-md bg-green-50 text-green-800 border border-green-200'
    } else {
      messageEl.className = 'mt-2 p-3 rounded-md bg-red-50 text-red-800 border border-red-200'
    }

    setTimeout(() => {
      if (type !== 'success') { // Keep success message visible until reload
        messageEl.classList.add('hidden')
      }
    }, 3000)
  }
}
