import { Controller } from "@hotwired/stimulus";
import { EDITOR_JS_RESOURCES, EDITOR_JS_CSS, initializeEditorUndo } from "panda/editor/editor_js_config";
import { ResourceLoader } from "panda/editor/resource_loader";

// UTF-8 safe Base64 helpers — atob/btoa only handle Latin-1, corrupting multi-byte characters
function base64Decode(base64) {
  const binaryString = atob(base64);
  const bytes = Uint8Array.from(binaryString, (c) => c.charCodeAt(0));
  return new TextDecoder("utf-8").decode(bytes);
}

function base64Encode(str) {
  const bytes = new TextEncoder().encode(str);
  const binaryString = Array.from(bytes, (b) => String.fromCharCode(b)).join("");
  return btoa(binaryString);
}

export default class extends Controller {
  static targets = ["editorContainer", "hiddenField"];
  static values = {
    editorId: String,
    linkMetadataUrl: String,
    fileUploadUrl: String,
    editorSearchUrl: String,
  };

  connect() {
    this.loadEditorResources();
    // Enable submit button after a delay as fallback
    setTimeout(() => {
      this.enableSubmitButton();
    }, 1000);
  }

  async loadEditorResources() {
    try {
      // First load EditorJS core
      const editorCore = EDITOR_JS_RESOURCES[0];
      await ResourceLoader.loadScript(document, document.head, editorCore);

      // Load CSS
      await ResourceLoader.embedCSS(document, document.head, EDITOR_JS_CSS);

      // Then load all tools sequentially
      for (const resource of EDITOR_JS_RESOURCES.slice(1)) {
        await ResourceLoader.loadScript(document, document.head, resource);
      }

      await this.initializeEditor();
    } catch (error) {
      console.error("[Panda CMS] Failed to load editor resources:", error);
    }
  }

  async initializeEditor() {
    if (this.editor) return;

    // Set endpoint URLs for EditorJS tools (link, attaches)
    window.PANDA_CMS_EDITOR_JS_ENDPOINTS = {
      linkMetadata: this.linkMetadataUrlValue || undefined,
      fileUpload: this.fileUploadUrlValue || undefined,
      editorSearch: this.editorSearchUrlValue || undefined,
    };

    try {
      const holderId =
        this.editorIdValue + "_holder" ||
        `editor-${Math.random().toString(36).substring(2, 9)}`;
      let holderDiv = document.createElement("div");
      holderDiv.id = holderId;
      holderDiv.className = "codex-editor";
      this.editorContainerTarget.innerHTML = "";
      this.editorContainerTarget.appendChild(holderDiv);

      const { getEditorConfig } = await import(
        "panda/editor/editor_js_config"
      );

      // Get initial content before creating config
      const initialContent = this.getInitialContent();
      console.debug("[Panda CMS] Using initial content:", initialContent);

      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

      const config = {
        ...getEditorConfig(holderId, initialContent),
        holder: holderId,
        data: initialContent,
        autofocus: false,
        minHeight: 1,
        logLevel: "ERROR",
        onChange: () => {
          if (!this.editor) return;
          this.editor.save().then((outputData) => {
            outputData.source = "editorJS";
            const jsonString = JSON.stringify(outputData);
            // Store both base64 and regular JSON
            this.editorContainerTarget.dataset.editablePreviousData = base64Encode(jsonString);
            this.editorContainerTarget.dataset.editableContent = jsonString;
            this.hiddenFieldTarget.value = jsonString;
          });
        },
        onReady: () => {
          console.debug("[Panda CMS] Editor ready with content:", initialContent);
          this.editorContainerTarget.dataset.editorInitialized = "true";
          holderDiv.dataset.editorInitialized = "true";
          // Add a class to indicate the editor is ready
          holderDiv.classList.add("editor-ready");
          // Enable the submit button
          this.enableSubmitButton();
          // Dispatch an event when editor is ready
          this.editorContainerTarget.dispatchEvent(new CustomEvent("editor:ready"));
        },
        tools: {
          paragraph: {
            class: window.Paragraph,
            inlineToolbar: true
          },
          header: {
            class: window.Header,
            inlineToolbar: true
          },
          list: {
            class: window.NestedList,
            inlineToolbar: true,
            config: {
              defaultStyle: 'unordered',
              enableLineBreaks: true
            }
          },
          quote: {
            class: window.Quote,
            inlineToolbar: true
          },
          table: {
            class: window.Table,
            inlineToolbar: true
          },
          linkTool: {
            class: window.LinkTool,
            config: {
              endpoint: window.PANDA_CMS_EDITOR_JS_ENDPOINTS?.linkMetadata,
              headers: {
                'X-CSRF-Token': csrfToken
              }
            }
          },
          attaches: {
            class: window.AttachesTool,
            config: {
              endpoint: window.PANDA_CMS_EDITOR_JS_ENDPOINTS?.fileUpload,
              field: 'file',
              buttonText: 'Select file to upload',
              additionalRequestHeaders: {
                'X-CSRF-Token': csrfToken
              }
            }
          },
          link: {
            class: window.LinkAutocomplete,
            config: {
              endpoint: window.PANDA_CMS_EDITOR_JS_ENDPOINTS?.editorSearch,
              queryParam: 'search'
            }
          }
        }
      };

      // Ensure EditorJS is available
      const EditorJS = window.EditorJS;
      if (!EditorJS) {
        throw new Error("EditorJS not loaded");
      }

      this.editor = new EditorJS(config);

      // Wait for editor to be ready
      await this.editor.isReady;
      initializeEditorUndo(this.editor, window);
      console.debug("[Panda CMS] Editor initialized successfully");

    } catch (error) {
      console.error("[Panda CMS] Editor setup failed:", error);
      this.editorContainerTarget.dataset.editorInitialized = "false";
      if (holderDiv) {
        holderDiv.dataset.editorInitialized = "false";
        holderDiv.classList.remove("editor-ready");
      }
      // Still enable the submit button even if editor fails
      this.enableSubmitButton();
    }
  }

  getInitialContent() {
    try {
      const initialContent = this.hiddenFieldTarget.getAttribute("data-initial-content");
      if (initialContent && initialContent !== "{}") {
        try {
          // First try to decode as base64
          try {
            const decodedData = base64Decode(initialContent);
            const data = JSON.parse(decodedData);
            if (data.blocks) return data;
          } catch (e) {
            // If base64 decode fails, try direct JSON parse
            const data = JSON.parse(initialContent);
            if (data.blocks) return data;
          }
        } catch (e) {
          console.error("[Panda CMS] Failed to parse content:", e);
        }
      }

      // Try to get content from the editor container's data attributes
      const previousData = this.editorContainerTarget.dataset.editablePreviousData;
      const editorContent = this.editorContainerTarget.dataset.editableContent;

      if (previousData) {
        try {
          const decodedData = base64Decode(previousData);
          const data = JSON.parse(decodedData);
          if (data.blocks) return data;
        } catch (e) {
          console.debug("[Panda CMS] Failed to parse base64 data:", e);
        }
      }

      if (editorContent && editorContent !== "{}") {
        try {
          const data = JSON.parse(editorContent);
          if (data.blocks) return data;
        } catch (e) {
          console.debug("[Panda CMS] Failed to parse editor content:", e);
        }
      }
    } catch (e) {
      console.warn("[Panda CMS] Could not parse initial content:", e);
    }

    // Return default content if nothing else works
    return {
      time: Date.now(),
      blocks: [{ type: "paragraph", data: { text: "" } }],
      version: "2.28.2",
      source: "editorJS",
    };
  }
  
  enableSubmitButton() {
    // Find the submit button in the form and enable it
    const form = this.element.closest('form');
    if (form) {
      const submitButton = form.querySelector('input[type="submit"], button[type="submit"]');
      if (submitButton) {
        submitButton.disabled = false;
      }
    }
  }

  async submit(event) {
    // Prevent the default button click behavior temporarily
    event.preventDefault();

    const submitButton = event.currentTarget;
    const form = submitButton.closest('form');

    // Re-enable the button that was disabled by data-disable-with
    submitButton.disabled = false;

    // Ensure editor content is saved before form submission
    if (this.editor) {
      try {
        const outputData = await this.editor.save();
        outputData.source = "editorJS";
        const jsonString = JSON.stringify(outputData);
        this.hiddenFieldTarget.value = jsonString;
        console.log("[Panda CMS] Editor content saved before submission");
      } catch (error) {
        console.error("[Panda CMS] Failed to save editor content:", error);
      }

      // Destroy the editor before form submission so its document-level
      // click handler is removed. Without this, the *original* trusted click
      // can keep bubbling after `submit()` returns, reach `document`, and
      // trigger EditorJS's `documentClicked`, which then tries to access
      // toolbar DOM elements that Turbo has already removed — causing
      // "Cannot read properties of undefined (reading 'classList')". The
      // synthetic click we dispatch below is non-trusted and ignored by
      // `documentClicked` in the vendored EditorJS build.
      try {
        this.editor.destroy();
      } catch (e) {
        console.debug("[Panda CMS] Editor cleanup before submit (safe to ignore):", e.message);
      }
      this.editor = null;
    }

    // Now trigger the normal form submission (this will let Rails/Turbo handle it properly)
    if (form) {
      // Remove our custom action to prevent infinite loop
      submitButton.removeAttribute('data-action');

      // Create a new click event that will trigger the normal form submission
      const clickEvent = new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        view: window
      });

      // Dispatch the click event, which will trigger normal Rails form submission
      submitButton.dispatchEvent(clickEvent);
    }
  }

  disconnect() {
    if (this.editor && typeof this.editor.destroy === 'function') {
      try {
        this.editor.destroy();
      } catch (error) {
        console.debug("[Panda CMS] Editor cleanup error (safe to ignore):", error.message);
      }
      this.editor = null;
    }
  }
}
