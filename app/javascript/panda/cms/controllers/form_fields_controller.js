import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label", "name", "fieldType", "optionsSection"]

  connect() {
    // Initialize options section visibility for all existing fields
    this.element.querySelectorAll('[data-form-fields-target="fieldType"]').forEach(select => {
      this.updateOptionsVisibility(select)
    })
  }

  // Auto-generate name from label
  generateName(event) {
    const labelInput = event.target
    const wrapper = labelInput.closest('.nested-form-wrapper')
    if (!wrapper) return

    const nameInput = wrapper.querySelector('[data-form-fields-target="name"]')
    if (!nameInput) return

    // Only auto-generate if name is empty or matches previous auto-generated value
    const currentName = nameInput.value
    const previousLabel = labelInput.dataset.previousValue || ""
    const previousAutoName = this.slugify(previousLabel)

    if (currentName === "" || currentName === previousAutoName) {
      nameInput.value = this.slugify(labelInput.value)
    }

    labelInput.dataset.previousValue = labelInput.value
  }

  // Convert label to snake_case name
  slugify(text) {
    return text
      .toLowerCase()
      .replace(/[^a-z0-9\s_]/g, '')  // Remove special chars except spaces and underscores
      .replace(/\s+/g, '_')           // Replace spaces with underscores
      .replace(/_+/g, '_')            // Collapse multiple underscores
      .replace(/^_|_$/g, '')          // Trim underscores from start/end
  }

  // Handle field type change to show/hide options section
  fieldTypeChanged(event) {
    this.updateOptionsVisibility(event.target)
  }

  updateOptionsVisibility(selectElement) {
    const wrapper = selectElement.closest('.nested-form-wrapper')
    if (!wrapper) return

    const optionsSection = wrapper.querySelector('[data-form-fields-target="optionsSection"]')
    if (!optionsSection) return

    const fieldType = selectElement.value
    const optionTypes = ['select', 'checkbox', 'radio']

    if (optionTypes.includes(fieldType)) {
      optionsSection.classList.remove('hidden')
    } else {
      optionsSection.classList.add('hidden')
    }
  }
}
