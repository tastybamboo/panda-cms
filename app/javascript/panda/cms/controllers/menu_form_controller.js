import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startPageField", "menuItemsSection"]

  connect() {
    console.log("Menu form controller connected")
    // Initialize visibility based on current kind selection
    this.updateFieldsVisibility()
  }

  kindChanged(event) {
    console.log("[menu-form] kindChanged called", event)
    this.updateFieldsVisibility()
  }

  updateFieldsVisibility() {
    console.log("[menu-form] updateFieldsVisibility called")
    const kindSelect = this.element.querySelector('select[name*="[kind]"]')
    console.log("[menu-form] kindSelect found:", !!kindSelect)

    if (!kindSelect) {
      console.error("[menu-form] Could not find kind select!")
      return
    }

    const selectedKind = kindSelect.value
    console.log("[menu-form] selectedKind:", selectedKind)

    if (selectedKind === "auto") {
      // Show start page field, hide menu items section
      console.log("[menu-form] AUTO - Showing start page field")
      if (this.hasStartPageFieldTarget) {
        console.log("[menu-form] Removing hidden from start page field")
        this.startPageFieldTarget.classList.remove("hidden")
      } else {
        console.error("[menu-form] Start page field target not found!")
      }
      if (this.hasMenuItemsSectionTarget) {
        this.menuItemsSectionTarget.classList.add("hidden")
      }
    } else {
      // Hide start page field, show menu items section
      console.log("[menu-form] STATIC - Hiding start page field")
      if (this.hasStartPageFieldTarget) {
        this.startPageFieldTarget.classList.add("hidden")
      }
      if (this.hasMenuItemsSectionTarget) {
        this.menuItemsSectionTarget.classList.remove("hidden")
      }
    }
  }
}
