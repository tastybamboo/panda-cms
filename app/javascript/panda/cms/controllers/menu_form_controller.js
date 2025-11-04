import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startPageField", "menuItemsSection"]

  connect() {
    console.log("Menu form controller connected")
    // Initialize visibility based on current kind selection
    this.updateFieldsVisibility()
  }

  kindChanged(event) {
    this.updateFieldsVisibility()
  }

  updateFieldsVisibility() {
    const kindSelect = this.element.querySelector('select[name*="[kind]"]')
    if (!kindSelect) return

    const selectedKind = kindSelect.value

    if (selectedKind === "auto") {
      // Show start page field, hide menu items section
      if (this.hasStartPageFieldTarget) {
        this.startPageFieldTarget.classList.remove("hidden")
      }
      if (this.hasMenuItemsSectionTarget) {
        this.menuItemsSectionTarget.classList.add("hidden")
      }
    } else {
      // Hide start page field, show menu items section
      if (this.hasStartPageFieldTarget) {
        this.startPageFieldTarget.classList.add("hidden")
      }
      if (this.hasMenuItemsSectionTarget) {
        this.menuItemsSectionTarget.classList.remove("hidden")
      }
    }
  }
}
