export class PlainTextEditor {
  /**
   * Constructs a new PlainTextEditor instance.
   *
   * @param {HTMLElement} element - The HTML element representing the plain text editor.
   * @param {HTMLIFrameElement} frame - The HTML iframe element containing the plain text editor.
   * @param {Object} options - An object containing configuration options for the plain text editor.
   */
  constructor(element, frame, options) {
    this.element = element
    this.frame = frame
    this.options = options
    this.setupStyles()
    this.bindEvents()
  }

  /**
   * Sets up the styles for the plain text editor element.
   *
   * This method applies various CSS styles to the editor element, such as a dashed border, no outline, a pointer cursor, and a background color transition. It also sets the white-space and font-family styles based on the data-editable-kind attribute of the element.
   */
  setupStyles() {
    this.element.style.border = "1px dashed #ccc"
    this.element.style.outline = "none"
    this.element.style.cursor = "pointer"
    this.element.style.transition = "background 500ms linear"
    this.element.style.backgroundColor = "inherit"

    if (this.element.getAttribute("data-editable-kind") == "html") {
      this.element.style.whiteSpace = "pre-wrap"
      this.element.style.fontFamily = "monospace"
    }
  }

  /**
   * Binds event listeners for the plain text editor.
   *
   * If the `autosave` option is enabled, this method adds a `blur` event listener to the editor element, which triggers the `save()` method when the editor loses focus.
   *
   * Additionally, this method adds a `click` event listener to the "Save Editable" button, which also triggers the `save()` method when clicked.
   */
  bindEvents() {
    if (this.options.autosave) {
      this.element.addEventListener("blur", () => this.save())
    }

    document.getElementById('saveEditableButton').addEventListener('click', () => this.save())
  }

  /**
   * Saves the content of the plain text editor to the server.
   *
   * This method sends a PATCH request to the server with the updated content of the plain text editor. It retrieves the necessary data from the editor element's attributes, such as the block content ID and the content type (HTML or plain text). If the save is successful, it calls the `showSuccess()` method, otherwise it calls the `showError()` method with the error.
   */
  save() {
    const blockContentId = this.element.getAttribute("data-editable-block-content-id")
    const pageId = this.element.getAttribute("data-editable-page-id")
    const content = this.element.getAttribute("data-editable-kind") == "html" ?
      this.element.innerHTML :
      this.element.innerText

    fetch(`${this.options.adminPath}/pages/${pageId}/block_contents/${blockContentId}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.options.csrfToken
      },
      body: JSON.stringify({ content: content })
    })
      .then(response => response.json())
      .then(() => {
        // Show success message in parent window
        parent.document.getElementById("successMessage").classList.remove("hidden")
        setTimeout(() => {
          parent.document.getElementById("successMessage").classList.add("hidden")
        }, 3000)
        // Show visual feedback in the editor
        this.showSuccess()
      })
      .catch(error => this.showError(error))
  }

  /**
   * Displays a success message by temporarily changing the background color of the editor element.
   *
   * This method is called after a successful save operation to provide visual feedback to the user.
   */
  showSuccess() {
    this.element.style.backgroundColor = "#66bd6a50"
    setTimeout(() => {
      this.element.style.backgroundColor = "inherit"
    }, 1000)
  }

  /**
   * Displays an error message by temporarily changing the background color of the editor element and logging the error to the console.
   *
   * This method is called after a failed save operation to provide visual and textual feedback to the user.
   *
   * @param {Error} error - The error object that occurred during the save operation.
   */
  showError(error) {
    this.element.style.backgroundColor = "#dc354550"
    setTimeout(() => {
      this.element.style.backgroundColor = "inherit"
    }, 1000)
    console.log(error)
    alert(`Error: ${error}`)
  }
}
