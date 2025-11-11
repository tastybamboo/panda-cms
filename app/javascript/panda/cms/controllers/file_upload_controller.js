import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "dropzone", "fileInfo", "removeButton"]

  connect() {
    // Setup drag and drop handlers
    if (this.hasDropzoneTarget) {
      this.setupDragAndDrop()
    }
  }

  setupDragAndDrop() {
    const dropzone = this.dropzoneTarget

    // Prevent default drag behaviors
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      dropzone.addEventListener(eventName, this.preventDefaults.bind(this), false)
      document.body.addEventListener(eventName, this.preventDefaults.bind(this), false)
    })

    // Highlight drop zone when item is dragged over it
    ['dragenter', 'dragover'].forEach(eventName => {
      dropzone.addEventListener(eventName, this.highlight.bind(this), false)
    })

    ;['dragleave', 'drop'].forEach(eventName => {
      dropzone.addEventListener(eventName, this.unhighlight.bind(this), false)
    })

    // Handle dropped files
    dropzone.addEventListener('drop', this.handleDrop.bind(this), false)
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  highlight(e) {
    this.dropzoneTarget.classList.add('border-indigo-600', 'bg-indigo-50', 'dark:bg-indigo-950', 'dark:border-indigo-400')
  }

  unhighlight(e) {
    this.dropzoneTarget.classList.remove('border-indigo-600', 'bg-indigo-50', 'dark:bg-indigo-950', 'dark:border-indigo-400')
  }

  handleDrop(e) {
    const dt = e.dataTransfer
    const files = dt.files

    if (files.length > 0) {
      // Update the file input with the dropped file
      this.inputTarget.files = files
      this.handleFileSelect()
    }
  }

  // Triggered when user selects file via input or drag-drop
  handleFileSelect() {
    const file = this.inputTarget.files[0]

    if (!file) {
      return
    }

    // Show file preview if it's an image
    if (file.type.startsWith('image/')) {
      this.showImagePreview(file)
    } else {
      this.showFileInfo(file)
    }
  }

  showImagePreview(file) {
    const reader = new FileReader()

    reader.onload = (e) => {
      if (this.hasPreviewTarget) {
        // Create or update preview image
        const existingImage = this.previewTarget.querySelector('img')
        if (existingImage) {
          existingImage.src = e.target.result
        } else {
          const img = document.createElement('img')
          img.src = e.target.result
          img.className = 'max-w-xs rounded border border-gray-300 dark:border-gray-600'
          this.previewTarget.innerHTML = ''
          this.previewTarget.appendChild(img)
        }
        this.previewTarget.classList.remove('hidden')
      }

      // Show file info with remove button
      this.showFileInfo(file, true)
    }

    reader.readAsDataURL(file)
  }

  showFileInfo(file, withPreview = false) {
    if (!this.hasFileInfoTarget) {
      return
    }

    const fileSize = this.humanFileSize(file.size)
    const fileName = file.name

    this.fileInfoTarget.innerHTML = `
      <div class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-md">
        <div class="flex items-center gap-x-3 flex-1 min-w-0">
          <svg class="size-8 text-gray-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
          </svg>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-900 dark:text-white truncate">${fileName}</p>
            <p class="text-xs text-gray-500 dark:text-gray-400">${fileSize}</p>
          </div>
        </div>
        <button type="button"
                data-action="click->file-upload#removeFile"
                class="flex-shrink-0 ml-3 text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300">
          <svg class="size-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    `
    this.fileInfoTarget.classList.remove('hidden')

    // Hide the dropzone upload area
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.add('hidden')
    }
  }

  removeFile() {
    // Clear the file input
    this.inputTarget.value = ''

    // Hide preview and file info
    if (this.hasPreviewTarget) {
      this.previewTarget.classList.add('hidden')
      this.previewTarget.innerHTML = ''
    }

    if (this.hasFileInfoTarget) {
      this.fileInfoTarget.classList.add('hidden')
      this.fileInfoTarget.innerHTML = ''
    }

    // Show the dropzone again
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove('hidden')
    }
  }

  humanFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
  }
}
