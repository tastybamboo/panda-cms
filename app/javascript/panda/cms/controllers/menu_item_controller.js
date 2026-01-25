import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "pageSelect"]

  connect() {
    console.log("Menu item controller connected")
    // Store the current page title for comparison
    this.updateCurrentPageTitle()
  }

  pageChanged(event) {
    console.log("[menu-item] pageChanged called")
    const pageSelect = this.pageSelectTarget
    const textField = this.textTarget

    // Get the selected option's text
    const selectedOption = pageSelect.options[pageSelect.selectedIndex]
    if (!selectedOption || !selectedOption.value) {
      return
    }

    // Extract the page title from the display text (format: "- - Title (path)")
    const displayText = selectedOption.text
    const titleMatch = displayText.match(/^[-\s]*(.*?)\s+\(/)
    if (!titleMatch) {
      return
    }

    const newPageTitle = titleMatch[1].trim()

    // Auto-populate the text field if:
    // 1. It's empty, OR
    // 2. It contains the previous page's title
    if (!textField.value || textField.value === this.currentPageTitle) {
      console.log(`[menu-item] Updating menu text from "${textField.value}" to "${newPageTitle}"`)
      textField.value = newPageTitle
    }

    // Update the stored current page title
    this.currentPageTitle = newPageTitle
  }

  updateCurrentPageTitle() {
    const pageSelect = this.pageSelectTarget
    const selectedOption = pageSelect.options[pageSelect.selectedIndex]

    if (selectedOption && selectedOption.value) {
      const displayText = selectedOption.text
      const titleMatch = displayText.match(/^[-\s]*(.*?)\s+\(/)
      if (titleMatch) {
        this.currentPageTitle = titleMatch[1].trim()
      }
    }
  }
}
