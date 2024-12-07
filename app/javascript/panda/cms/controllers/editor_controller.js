import { Controller } from "@hotwired/stimulus"
import { PlainTextEditor } from "panda/cms/editor/plain_text_editor";
import { ResourceLoader } from "panda/cms/editor/resource_loader";

export class EditorController extends Controller {
  /**
   * Defines the static values that can be set on the EditorController.
   *
   * @property {number} pageId - The ID of the page being edited.
   * @property {string} adminPath - The path to the admin section of the application.
   * @property {boolean} autosave - Whether the editor should automatically save changes.
   */
  static values = {
    pageId: Number,
    adminPath: String,
    autosave: Boolean
  }

  /**
   * Connects the EditorController to the DOM and initializes the editors.
   * This method is called when the EditorController is connected to the DOM.
   * It sets up the necessary properties and event listeners to manage the editors,
   * and then calls the `initializeEditors()` method to start the initialization process.
   */
  connect() {
    console.debug("[Panda CMS] Editor controller connected")
    this.frame = this.element

    // Create editor controls if they don't exist
    if (!parent.document.querySelector('.editor-controls')) {
      const controls = parent.document.createElement('div')
      controls.className = 'editor-controls'
      parent.document.body.appendChild(controls)
    }

    // In CI, show what's going on, otherwise hide the frame
    if (!window.location.href.includes("0.0.0.0:3001")) {
      this.frame.style.display = "none"
    }

    if (document.querySelector('meta[name="csrf-token"]')) {
      this.csrfToken = document.querySelector('meta[name="csrf-token"]').content
    } else {
      this.csrfToken = ""
    }

    this.editors = []
    this.editorsInitialized = {
      plain: false,
      rich: false
    }

    this.frame.addEventListener("load", () => {
      console.debug("[Panda CMS] Frame loaded")
      this.frameDocument = this.frame.contentDocument || this.frame.contentWindow.document
      this.body = this.frameDocument.body
      this.head = this.frameDocument.head
      this.initializeEditors()
    })
  }

  /**
   * Initializes the plain text and rich text editors for the page.
   * This method is responsible for finding all editable elements on the page and initializing the appropriate editor instances for them.
   * It sets the editorsInitialized flags to true once the initialization is complete and calls the checkAllEditorsInitialized method.
   */
  initializeEditors() {
    console.debug("[Panda CMS] Starting editor initialization")
    this.initializePlainTextEditors()
    this.initializeRichTextEditors()
  }

  /**
   * Initializes the plain text editors for the page.
   * This method is responsible for finding all elements on the page that have the "plain_text", "markdown", or "html" data-editable-kind attributes,
   * and initializing a PlainTextEditor instance for each of them. It also sets the editorsInitialized.plain flag to true
   * and calls the checkAllEditorsInitialized method to notify that the plain text editors have been initialized.
   */
  initializePlainTextEditors() {
    const plainTextElements = this.body.querySelectorAll('[data-editable-kind="plain_text"], [data-editable-kind="markdown"], [data-editable-kind="html"]')
    console.debug(`[Panda CMS] Found ${plainTextElements.length} plain text elements`)

    plainTextElements.forEach(element => {

      const editor = new PlainTextEditor(element, this.frameDocument, {
        autosave: this.autosaveValue,
        adminPath: this.adminPathValue,
        csrfToken: this.csrfToken
      })
      this.editors.push(editor)
    })

    this.editorsInitialized.plain = true
    this.checkAllEditorsInitialized()
  }

  /**
   * Initializes the rich text editors for the page.
   * This method is responsible for finding all elements on the page that have the "rich_text" data-editable-kind attribute,
   * and initializing a RichTextEditor instance for each of them. It also sets the editorsInitialized.rich flag to true
   * and calls the checkAllEditorsInitialized method to notify that the rich text editors have been initialized.
   */
  initializeRichTextEditors() {
    const richTextElements = this.body.querySelectorAll('[data-editable-kind="rich_text"]')
    console.debug(`[Panda CMS] Found ${richTextElements.length} rich text elements`)

    if (richTextElements.length > 0) {
      // Add save button if it doesn't exist
      if (!parent.document.getElementById('saveEditableButton')) {
        const saveButton = parent.document.createElement('a')
        saveButton.id = 'saveEditableButton'
        saveButton.href = '#'
        saveButton.textContent = 'Save Changes'
        saveButton.className = 'btn btn-primary'
        parent.document.querySelector('.editor-controls').appendChild(saveButton)
      }

      Promise.all([
        ResourceLoader.loadScript(this.frameDocument, this.head, "https://cdn.jsdelivr.net/npm/@editorjs/editorjs@latest"), // Base EditorJS
        ResourceLoader.loadScript(this.frameDocument, this.head, "https://cdn.jsdelivr.net/npm/@editorjs/header@latest"), // Header Tool
        ResourceLoader.loadScript(this.frameDocument, this.head, "https://cdn.jsdelivr.net/npm/@editorjs/list@latest"), // List Tool
        ResourceLoader.loadScript(this.frameDocument, this.head, "https://cdn.jsdelivr.net/npm/@editorjs/quote@latest"), // Quote Tool
        ResourceLoader.loadScript(this.frameDocument, this.head, "https://cdn.jsdelivr.net/npm/@editorjs/nested-list@latest"), // Nested List Tool
        ResourceLoader.loadScript(this.frameDocument, this.head, "https://cdn.jsdelivr.net/npm/@editorjs/simple-image@latest"), // Simple Image Tool
        ResourceLoader.loadScript(this.frameDocument, this.head, "https://cdn.jsdelivr.net/npm/@editorjs/table@latest"), // Table Tool
        ResourceLoader.loadScript(this.frameDocument, this.head, "https://cdn.jsdelivr.net/npm/@editorjs/embed@latest"), // Link Tool
        ResourceLoader.loadScript(this.frameDocument, this.head, "https://cdn.jsdelivr.net/npm/editorjs-alert@latest"), // Alert Tool
        ResourceLoader.embedCSS(this.frameDocument, this.head, ".ce-toolbar__content { margin: 0 !important; margin-left: 40px; max-width: 100% !important; width: 100% !important; } .ce-block__content { max-width: 100%; margin: 0 !important; margin-left: 10px !important; }")
      ]).then(() => {
        richTextElements.forEach(element => {
          console.debug(`[Panda CMS] Initializing rich text editor for element:`, element)

          // TODO: Need a way to override this per-site ... or rather, block/editor?
          const elementAsId = element.id.replace(/-/g, "_")
          const adminPathValue = this.adminPathValue
          const pageId = element.getAttribute("data-editable-page-id")
          const blockContentId = element.getAttribute("data-editable-block-content-id")
          const csrfToken = this.csrfToken
          const previousData = element.getAttribute("data-editable-previous-data")
          const editorConfig = `{
            holder: '${element.id}',
            data: ${previousData},
            tools: {
              header: {
                class: Header,
                config: {
                  placeholder: 'Enter a header',
                  levels: [2, 3],
                  defaultLevel: 2
                }
              },
              list: {
                class: NestedList,
                inlineToolbar: true,
                config: {
                  defaultStyle: 'unordered'
                },
              },
              alert: {
                class: Alert,
                inlineToolbar: true,
                config: {
                  defaultType: 'primary',
                  messagePlaceholder: 'Enter something',
                  types: {
                    primary: 'Primary',
                    secondary: 'Secondary',
                    success: 'Success',
                    danger: 'Danger',
                    warning: 'Warning',
                    info: 'Info'
                  }
                }
              },
              quote: Quote,
              table: {
                class: Table,
                inlineToolbar: true,
                config: {
                  rows: 2,
                  cols: 3
                }
              },
              image: SimpleImage,
              embed: {
                class: Embed,
                config: {
                  services: {
                    youtube: true,
                    instagram: true,
                    miro: true,
                    vimeo: true,
                    pinterest: true,
                    github: true
                  }
                }
              },
            }
          }`

          // console.log(editorConfig);

          ResourceLoader.embedScript(
            `EditorJS configuration for ${element.id}`,
            this.frameDocument,
            this.head,
            `
              const ${elementAsId} = new EditorJS(${editorConfig})
              parent.document.getElementById('saveEditableButton').addEventListener('click', (element) => {
                ${elementAsId}.save().then((outputData) => {
                  outputData.source = "editorJS"
                  // console.log('Saving successful, here is outputData:')
                  dataToSend = JSON.stringify({ content: outputData })
                  console.log(dataToSend)
                  fetch("${adminPathValue}/pages/${pageId}/block_contents/${blockContentId}", {
                    method: "PATCH",
                    headers: {
                      "Content-Type": "application/json",
                      "X-CSRF-Token": "${this.csrfToken}"
                    },
                    body: dataToSend
                  })
                  .then(response => console.log(response))
                  .then((success) => {
                    parent.document.getElementById("successMessage").classList.remove("hidden")
                    setTimeout(() => {
                      parent.document.getElementById("successMessage").classList.add("hidden")
                    }, 3000)
                  })
                  .catch((error) => {
                    parent.document.getElementById("errorMessage").getElementsByClassName('flash-message-text')[0].textContent = error
                    parent.document.getElementById("errorMessage").classList.remove("hidden")
                    setTimeout(() => {
                      parent.document.getElementById("errorMessage").classList.add("hidden")
                    }, 3000)
                    console.error(error)
                  })
                }).catch((error) => {
                    parent.document.getElementById("errorMessage").getElementsByClassName('flash-message-text')[0].textContent = error
                    parent.document.getElementById("errorMessage").classList.remove("hidden")
                    setTimeout(() => {
                      parent.document.getElementById("errorMessage").classList.add("hidden")
                    }, 3000)
                    console.error(error)
                })
              })

              console.debug("[Panda CMS] Initialized rich text editor for element: ${elementAsId}")
            `
          )
          this.editors.push(elementAsId)
        })
      }).then(() => {
        this.editorsInitialized.rich = true
        this.checkAllEditorsInitialized()
      })
    } else {
      this.editorsInitialized.rich = true
      this.checkAllEditorsInitialized()
    }
  }

  /**
   * Checks if all editors have been initialized and sets the iFrame to visible if so.
   * This is called after the plain text and rich text editors have been initialized.
   */
  checkAllEditorsInitialized() {
    console.debug("[Panda CMS] Editor initialization status:", this.editorsInitialized)
    if (this.editorsInitialized.plain && this.editorsInitialized.rich) {
      console.debug("[Panda CMS] All editors initialized, showing iFrame")
      this.setiFrameVisible()
    }
  }

  /**
   * Sets the visibility of the iFrame to visible.
   * This is called after all editors have been initialized to show the iFrame.
   */
  setiFrameVisible() {
    console.debug("[Panda CMS] Setting iFrame to visible")
    this.frame.style.display = ""
  }
}
