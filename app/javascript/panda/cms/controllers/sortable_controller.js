import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    console.log("Sortable controller connected")
    this.sortable = Sortable.create(this.containerTarget, {
      animation: 150,
      handle: ".drag-handle",
      ghostClass: "opacity-50",
      onEnd: this.updatePositions.bind(this)
    })

    // Initialize positions on load
    this.updatePositions()

    // Watch for new items being added via nested-form controller
    const observer = new MutationObserver(() => {
      this.updatePositions()
    })

    observer.observe(this.containerTarget, {
      childList: true
    })

    this.observer = observer
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  updatePositions() {
    // Update hidden sort_order fields based on current DOM order
    const items = this.containerTarget.querySelectorAll(".nested-form-wrapper")
    items.forEach((item, index) => {
      const sortOrderField = item.querySelector('input[name*="[sort_order]"]')
      if (sortOrderField) {
        sortOrderField.value = index + 1
      }
    })
  }
}
