import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slideoverContent"]
  static values = { filesPath: String }

  selectFile(event) {
    const button = event.currentTarget
    const fileData = {
      id: button.dataset.fileId,
      url: button.dataset.fileUrl,
      name: button.dataset.fileName,
      size: button.dataset.fileSize,
      type: button.dataset.fileType,
      created: button.dataset.fileCreated
    }

    // Update slideover content
    this.updateSlideover(fileData)

    // Update selected state
    this.updateSelectedState(button)
  }

  updateSlideover(fileData) {
    if (!this.hasSlideoverContentTarget) return

    // Build the slideover content HTML
    const html = this.buildSlideoverHTML(fileData)
    this.slideoverContentTarget.innerHTML = html

    // Show the slideover if it's hidden
    const slideover = document.getElementById("slideover")
    if (slideover && slideover.classList.contains("hidden")) {
      slideover.classList.remove("hidden")
    }

    // Trigger the toggle controller to show the slideover
    const toggleController = this.application.getControllerForElementAndIdentifier(
      document.getElementById("panda-inner-container"),
      "toggle"
    )
    if (toggleController) {
      toggleController.show()
    }
  }

  updateSelectedState(selectedButton) {
    // Remove selected state from all file items
    const allFileItems = this.element.querySelectorAll('[data-action*="file-gallery#selectFile"]')
    allFileItems.forEach(button => {
      const container = button.closest('.relative').querySelector('.group')
      if (container) {
        container.classList.remove('outline', 'outline-2', 'outline-offset-2', 'outline-panda-dark', 'dark:outline-panda-light')
        container.classList.add('focus-within:outline-2', 'focus-within:outline-offset-2', 'focus-within:outline-primary-600')
      }
    })

    // Add selected state to clicked item
    const container = selectedButton.closest('.relative').querySelector('.group')
    if (container) {
        container.classList.add('outline', 'outline-2', 'outline-offset-2', 'outline-panda-dark', 'dark:outline-panda-light')
        container.classList.remove('focus-within:outline-2', 'focus-within:outline-offset-2', 'focus-within:outline-primary-600')
    }
  }

  buildSlideoverHTML(fileData) {
    const isImage = fileData.type && fileData.type.startsWith('image/')
    const humanSize = this.humanFileSize(parseInt(fileData.size))
    const createdDate = new Date(fileData.created).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })

    return `
      <div>
        <div class="block overflow-hidden w-full rounded-2xl aspect-h-7 aspect-w-10">
          ${isImage ?
            `<img src="${fileData.url}" alt="${fileData.name}" class="object-cover" onerror="this.onerror=null;this.style.display='none';this.nextElementSibling.classList.remove('hidden')">
            <div class="hidden flex items-center justify-center h-full bg-gray-100" role="img" aria-label="Image preview not available">
              <i class="fa-solid fa-file-image text-4xl text-gray-400"></i>
            </div>` :
            `<div class="flex items-center justify-center h-full bg-gray-100">
              <div class="text-center">
                <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
                </svg>
                <p class="mt-1 text-xs text-gray-500 uppercase">${fileData.type ? fileData.type.split('/')[1] : 'file'}</p>
              </div>
            </div>`
          }
        </div>
        <div class="flex justify-between items-start mt-4">
          <div>
            <h2 class="text-lg font-medium text-gray-900">
              <span class="sr-only">Details for </span>${fileData.name}
            </h2>
            <p class="text-sm font-medium text-gray-500">${humanSize}</p>
          </div>
        </div>
      </div>

      <div>
        <h3 class="font-medium text-gray-900">Information</h3>
        <dl class="mt-2 border-t border-b border-gray-200 divide-y divide-gray-200">
          <div class="flex justify-between py-3 text-sm font-medium">
            <dt class="text-gray-500">Created</dt>
            <dd class="text-gray-900 whitespace-nowrap">${createdDate}</dd>
          </div>
          <div class="flex justify-between py-3 text-sm font-medium">
            <dt class="text-gray-500">Content Type</dt>
            <dd class="text-gray-900 whitespace-nowrap">${fileData.type || 'Unknown'}</dd>
          </div>
        </dl>
      </div>

      <div class="flex gap-x-3">
        <a href="${fileData.url}?disposition=attachment" class="flex-1 py-2 px-3 text-sm font-medium text-white bg-gray-900 rounded-xl shadow-sm hover:bg-gray-800 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-600 text-center">Download</a>
        <form action="${this.filesPathValue}/${fileData.id}" method="post" class="flex-1" data-turbo-confirm="Are you sure you want to delete this file?">
          <input type="hidden" name="_method" value="delete">
          <input type="hidden" name="authenticity_token" value="${this.csrfToken}">
          <button type="submit" class="w-full py-2 px-3 text-sm font-medium text-gray-700 bg-white rounded-xl border border-gray-200 shadow-sm hover:bg-gray-50">Delete</button>
        </form>
      </div>
    `
  }

  get csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.getAttribute("content") : ""
  }

  humanFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
  }
}
