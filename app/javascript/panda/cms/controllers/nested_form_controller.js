import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "target"]
  static values = {
    wrapperSelector: String
  }

  connect() {
    console.log("Nested form controller connected")
  }

  add(event) {
    event.preventDefault()

    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.targetTarget.insertAdjacentHTML('beforebegin', content)
  }

  remove(event) {
    event.preventDefault()

    const wrapper = event.target.closest(this.wrapperSelectorValue)

    if (wrapper.dataset.newRecord === "true") {
      wrapper.remove()
    } else {
      wrapper.style.display = 'none'
      const destroyInput = wrapper.querySelector("input[name*='_destroy']")
      if (destroyInput) {
        destroyInput.value = '1'
      }
    }
  }
}
