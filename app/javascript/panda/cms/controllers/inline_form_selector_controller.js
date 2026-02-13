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
    this.previewAreaTarget.replaceChildren()

    if (!selectedOption || !selectedOption.value) {
      const wrapper = document.createElement('div')
      wrapper.className = 'text-center py-8 text-gray-400'
      const msg = document.createElement('p')
      msg.className = 'text-sm'
      msg.textContent = 'No selection made. Choose an option from the dropdown above.'
      wrapper.appendChild(msg)
      this.previewAreaTarget.appendChild(wrapper)
      return
    }

    const wrapper = document.createElement('div')
    wrapper.className = 'text-center py-8 text-gray-500'
    const nameEl = document.createElement('p')
    nameEl.className = 'text-sm font-medium'
    nameEl.textContent = selectedOption.text.trim()
    const hintEl = document.createElement('p')
    hintEl.className = 'text-xs mt-1'
    hintEl.textContent = 'Save and reload to see the full preview.'
    wrapper.appendChild(nameEl)
    wrapper.appendChild(hintEl)
    this.previewAreaTarget.appendChild(wrapper)
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
          content: formId || "{}"
        })
      })

      if (response.ok) {
        this.showSaveMessage('Selection saved!', 'success')

        setTimeout(() => {
          window.location.reload()
        }, 1000)
      } else {
        this.showSaveMessage('Error saving selection', 'error')
      }
    } catch (error) {
      console.error('Error saving selection:', error)
      this.showSaveMessage('Error saving selection', 'error')
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
