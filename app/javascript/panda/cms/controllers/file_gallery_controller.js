import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['uploadBackdrop', 'uploadPanel']
  static values = { filesPath: String }

  connect() {
    this._handleFilenameInput = this.handleFilenameInput.bind(this)
    this._handleFilenameBlur = this.handleFilenameBlur.bind(this)
    document.addEventListener('input', this._handleFilenameInput)
    document.addEventListener('focusout', this._handleFilenameBlur)
  }

  disconnect() {
    document.removeEventListener('input', this._handleFilenameInput)
    document.removeEventListener('focusout', this._handleFilenameBlur)
  }

  handleFilenameInput(event) {
    if (event.target.id !== 'blob_filename') return
    const { selectionStart } = event.target
    event.target.value = event.target.value.replace(/\s/g, '_').replace(/[^a-z0-9_-]/gi, '')
    event.target.setSelectionRange(selectionStart, selectionStart)
  }

  handleFilenameBlur(event) {
    if (event.target.id !== 'blob_filename') return
    event.target.value = event.target.value.toLowerCase()
  }

  selectFile(event) {
    const button = event.currentTarget
    const fileId = button.dataset.fileId

    this.selectedFileId = fileId
    this.updateSelectedState(button)
    this.loadFileDetails(fileId)
  }

  async loadFileDetails(fileId) {
    const slideoverContent = document.getElementById('file-gallery-slideover-content')
    if (!slideoverContent) return

    // Show loading state
    slideoverContent.innerHTML =
      '<div class="flex items-center justify-center py-12"><i class="fa-solid fa-spinner fa-spin text-2xl text-gray-400"></i></div>'
    this.showSlideover()

    try {
      const response = await fetch(`${this.filesPathValue}/${fileId}`, {
        headers: { Accept: 'text/html' },
      })

      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      slideoverContent.innerHTML = await response.text()
    } catch {
      slideoverContent.innerHTML =
        '<div class="text-center py-12"><i class="fa-solid fa-exclamation-triangle text-2xl text-red-400 mb-2"></i><p class="text-sm text-gray-500">Failed to load file details</p></div>'
    }
  }

  showSlideover() {
    // Toggle controller is now a descendant (inside ContainerComponent)
    const toggleElement = this.element.querySelector('[data-controller*="toggle"]')
    if (!toggleElement) return

    const toggleController = this.application.getControllerForElementAndIdentifier(
      toggleElement,
      'toggle'
    )
    if (toggleController) {
      toggleController.show()
    }
  }

  reopenSlideover() {
    if (this.selectedFileId) {
      this.loadFileDetails(this.selectedFileId)
    }
  }

  openUpload() {
    this.uploadBackdropTarget.classList.remove('hidden')
    this.uploadPanelTarget.classList.remove('hidden')
  }

  closeUpload() {
    this.uploadBackdropTarget.classList.add('hidden')
    this.uploadPanelTarget.classList.add('hidden')
  }

  updateSelectedState(selectedButton) {
    // Remove selected state from all file items
    const allFileItems = this.element.querySelectorAll('[data-action*="file-gallery#selectFile"]')
    allFileItems.forEach((button) => {
      const container = button.closest('.relative').querySelector('.group')
      if (container) {
        container.classList.remove(
          'outline',
          'outline-2',
          'outline-offset-2',
          'outline-panda-dark',
          'dark:outline-panda-light'
        )
        container.classList.add(
          'focus-within:outline-2',
          'focus-within:outline-offset-2',
          'focus-within:outline-primary-600'
        )
      }
    })

    // Add selected state to clicked item
    const container = selectedButton.closest('.relative').querySelector('.group')
    if (container) {
      container.classList.add(
        'outline',
        'outline-2',
        'outline-offset-2',
        'outline-panda-dark',
        'dark:outline-panda-light'
      )
      container.classList.remove(
        'focus-within:outline-2',
        'focus-within:outline-offset-2',
        'focus-within:outline-primary-600'
      )
    }
  }
}
