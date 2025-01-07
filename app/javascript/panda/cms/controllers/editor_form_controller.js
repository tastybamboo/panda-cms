import { Controller } from "@hotwired/stimulus";
import { EDITOR_JS_RESOURCES, EDITOR_JS_CSS } from "panda/cms/editor/editor_js_config";
import { ResourceLoader } from "panda/cms/editor/resource_loader";

export default class extends Controller {
  static targets = ["editorContainer", "hiddenField"];
  static values = {
    editorId: String,
  };

  connect() {
    this.loadEditorResources();
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
        "panda/cms/editor/editor_js_config"
      );

      // Get initial content before creating config
      const initialContent = this.getInitialContent();
      console.debug("[Panda CMS] Using initial content:", initialContent);

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
            this.editorContainerTarget.dataset.editablePreviousData = btoa(jsonString);
            this.editorContainerTarget.dataset.editableContent = jsonString;
            this.hiddenFieldTarget.value = jsonString;
          });
        },
        onReady: () => {
          console.debug("[Panda CMS] Editor ready with content:", initialContent);
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
            class: window.List || window.NestedList,
            inlineToolbar: true
          },
          quote: {
            class: window.Quote,
            inlineToolbar: true
          },
          table: {
            class: window.Table,
            inlineToolbar: true
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
      console.debug("[Panda CMS] Editor initialized successfully");

    } catch (error) {
      console.error("[Panda CMS] Editor setup failed:", error);
    }
  }

  getInitialContent() {
    try {
      // Try to get content from the hidden field's data attribute
      const initialContent = this.hiddenFieldTarget.getAttribute("data-initial-content");
      if (initialContent && initialContent !== "{}") {
        try {
          // First try to decode as base64
          try {
            const decodedData = atob(initialContent);
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
          const decodedData = atob(previousData);
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

  disconnect() {
    if (this.editor) {
      this.editor.destroy();
      this.editor = null;
    }
  }
}
