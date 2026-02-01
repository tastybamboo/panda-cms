console.debug("[Panda CMS] Importing Panda CMS Stimulus Controller...")

import { application } from "../stimulus-loading.js"

console.debug("[Panda CMS] Using shared Stimulus application...")

const pandaCmsApplication = application

console.debug("[Panda CMS] Registering controllers...")

// Helper to safely load and register a controller with error reporting
async function registerController(name, path) {
  try {
    const module = await import(path)
    pandaCmsApplication.register(name, module.default)
    return true
  } catch (error) {
    console.error(`[Panda CMS] Failed to load controller "${name}" from ${path}:`, error.message)
    console.error(`[Panda CMS] Hint: Ensure the controller is pinned in config/importmap.rb`)
    return false
  }
}

// Define all CMS controllers with absolute paths for dynamic import resolution
const cmsControllers = [
  ["dashboard", "/panda/cms/controllers/dashboard_controller.js"],
  ["slug", "/panda/cms/controllers/slug_controller.js"],
  ["tree", "/panda/cms/controllers/tree_controller.js"],
  ["file-gallery", "/panda/cms/controllers/file_gallery_controller.js"],
  ["file-upload", "/panda/cms/controllers/file_upload_controller.js"],
  ["page-form", "/panda/cms/controllers/page_form_controller.js"],
  ["nested-form", "/panda/cms/controllers/nested_form_controller.js"],
  ["menu-form", "/panda/cms/controllers/menu_form_controller.js"],
  ["editor-form", "/panda/cms/controllers/editor_form_controller.js"],
  ["editor-iframe", "/panda/cms/controllers/editor_iframe_controller.js"],
  ["signature-pad", "/panda/cms/controllers/signature_pad_controller.js"]
]

// Load all controllers with error handling
Promise.all(
  cmsControllers.map(([name, path]) => registerController(name, path))
).then(results => {
  const loaded = results.filter(Boolean).length
  const failed = results.length - loaded

  if (failed > 0) {
    console.warn(`[Panda CMS] ${failed} controller(s) failed to load - check errors above`)
  }

  console.debug(`[Panda CMS] Loaded ${loaded}/${results.length} controllers`)
})

// Note: Toggle, Slideover, and other TailwindCSS Stimulus Components
// are now registered by Panda Core since the admin layout lives there

console.debug("[Panda CMS] Components registered...")

export { pandaCmsApplication }

console.debug("[Panda CMS] Application exported...")
