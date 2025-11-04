console.debug("[Panda CMS] Importing Panda CMS Stimulus Controller...")

import { application } from "../stimulus-loading.js"

console.debug("[Panda CMS] Using shared Stimulus application...")

const pandaCmsApplication = application

console.debug("[Panda CMS] Registering controllers...")

// Use relative imports with .js extensions for proper module resolution
import DashboardController from "./dashboard_controller.js"
pandaCmsApplication.register("dashboard", DashboardController)

import SlugController from "./slug_controller.js"
pandaCmsApplication.register("slug", SlugController)

import TreeController from "./tree_controller.js"
pandaCmsApplication.register("tree", TreeController)

import FileGalleryController from "./file_gallery_controller.js"
pandaCmsApplication.register("file-gallery", FileGalleryController)

import NestedFormController from "./nested_form_controller.js"
pandaCmsApplication.register("nested-form", NestedFormController)

import MenuFormController from "./menu_form_controller.js"
pandaCmsApplication.register("menu-form", MenuFormController)

// Lazy load editor controllers only when needed
// These will only be loaded when the data-controller attribute is present in the DOM
class EditorFormLazyController {
  connect() {
    // Only import the editor controller when it's actually needed in the DOM
    import("./editor_form_controller.js").then(module => {
      const Controller = module.default
      // Replace this lazy controller with the real one
      pandaCmsApplication.register("editor-form", Controller)
    }).catch(err => {
      console.error("[Panda CMS] Failed to load editor-form controller:", err)
    })
  }
}

class EditorIframeLazyController {
  connect() {
    // Only import the editor controller when it's actually needed in the DOM
    import("./editor_iframe_controller.js").then(module => {
      const Controller = module.default
      // Replace this lazy controller with the real one
      pandaCmsApplication.register("editor-iframe", Controller)
    }).catch(err => {
      console.error("[Panda CMS] Failed to load editor-iframe controller:", err)
    })
  }
}

// Register the lazy-loading proxy controllers
pandaCmsApplication.register("editor-form", EditorFormLazyController)
pandaCmsApplication.register("editor-iframe", EditorIframeLazyController)

// Note: Toggle, Slideover, and other TailwindCSS Stimulus Components
// are now registered by Panda Core since the admin layout lives there

console.debug("[Panda CMS] Components registered...")

export { pandaCmsApplication }

console.debug("[Panda CMS] Application exported...")
