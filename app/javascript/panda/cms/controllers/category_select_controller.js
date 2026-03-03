import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "toggleButton", "newCategoryFields", "newCategoryInput"]

  toggleNewCategory() {
    const isShowingNew = !this.newCategoryFieldsTarget.classList.contains("hidden")

    if (isShowingNew) {
      // Switch back to existing category select
      this.newCategoryFieldsTarget.classList.add("hidden")
      this.selectTarget.disabled = false
      this.newCategoryInputTarget.value = ""
      this.toggleButtonTarget.textContent = "+ Add new category"
    } else {
      // Switch to new category input
      this.newCategoryFieldsTarget.classList.remove("hidden")
      this.selectTarget.disabled = true
      this.newCategoryInputTarget.focus()
      this.toggleButtonTarget.textContent = "Choose existing category"
    }
  }
}
