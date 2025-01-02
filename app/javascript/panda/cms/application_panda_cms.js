import "@hotwired/turbo"
console.debug("[Panda CMS] Controllers loading...");
import "controllers"
console.debug("[Panda CMS] Controllers loaded...");

// Import editor resources
import { EDITOR_JS_RESOURCES, EDITOR_JS_CSS } from "panda/cms/editor/editor_js_config"
import { ResourceLoader } from "panda/cms/editor/resource_loader"

// Function to load editor resources
async function loadEditorResources() {
  console.debug("[Panda CMS] Loading editor resources...");
  try {
    // First load EditorJS core
    const editorCore = EDITOR_JS_RESOURCES[0]
    await ResourceLoader.loadScript(document, document.head, editorCore)

    // Then load all tools in parallel
    const toolLoads = EDITOR_JS_RESOURCES.slice(1).map(async (resource) => {
      await ResourceLoader.loadScript(document, document.head, resource)
    })

    // Load CSS directly since it's a string, not an array
    await ResourceLoader.embedCSS(document, document.head, EDITOR_JS_CSS)

    // Wait for all resources to load
    await Promise.all(toolLoads)
    console.debug("[Panda CMS] Editor resources loaded");

    // Dispatch a custom event when resources are loaded
    document.dispatchEvent(new CustomEvent('editorjs:loaded'))
  } catch (error) {
    console.error("[Panda CMS] Error loading editor resources:", error);
  }
}

// Load resources on both initial page load and Turbo cache restore
document.addEventListener('turbo:load', loadEditorResources);
document.addEventListener('turbo:render', loadEditorResources);
