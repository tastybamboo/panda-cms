import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["formSelect", "previewArea", "saveMessage"]
  static values = {
    pageId: String,
    blockContentId: String
  }

  connect() {
    // Form selector is ready
  }

  previewForm() {
    const selectedOption = this.formSelectTarget.selectedOptions[0]
    if (!selectedOption || !selectedOption.value) {
      this.previewAreaTarget.innerHTML = `
        <div class="text-center py-8 text-gray-400">
          <p class="text-sm">No form selected. Choose a form from the dropdown above.</p>
        </div>
      `
      return
    }

    const formName = selectedOption.text.trim()
    this.previewAreaTarget.innerHTML = `
      <div class="text-center py-8 text-gray-500">
        <p class="text-sm font-medium">${formName}</p>
        <p class="text-xs mt-1">Save and reload to see the full form preview.</p>
      </div>
    `
  }

  async saveSelection() {
    const formId = this.formSelectTarget.value
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
          content: formId
        })
      })

      if (response.ok) {
        this.showSaveMessage('Form selection saved!', 'success')

        setTimeout(() => {
          window.location.reload()
        }, 1000)
      } else {
        this.showSaveMessage('Error saving form selection', 'error')
      }
    } catch (error) {
      console.error('Error saving form selection:', error)
      this.showSaveMessage('Error saving form selection', 'error')
    }
  }

  showSaveMessage(message, type) {
    const messageEl = this.saveMessageTarget
    messageEl.textContent = message
    messageEl.classList.remove('hidden')

    if (type === 'success') {
      messageEl.className = 'ml-2 px-2 py-1 rounded text-xs bg-green-50 text-green-800 border border-green-200'
    } else {
      messageEl.className = 'ml-2 px-2 py-1 rounded text-xs bg-red-50 text-red-800 border border-red-200'
    }

    setTimeout(() => {
      if (type !== 'success') {
        messageEl.classList.add('hidden')
      }
    }, 3000)
  }
}
