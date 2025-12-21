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

import FileUploadController from "./file_upload_controller.js"
pandaCmsApplication.register("file-upload", FileUploadController)

import PageFormController from "./page_form_controller.js"
pandaCmsApplication.register("page-form", PageFormController)

import NestedFormController from "./nested_form_controller.js"
pandaCmsApplication.register("nested-form", NestedFormController)

import MenuFormController from "./menu_form_controller.js"
pandaCmsApplication.register("menu-form", MenuFormController)

// Editor controllers - loaded eagerly since they're essential for CMS functionality
// Note: Previous lazy-loading pattern was broken (didn't extend Controller, dynamic import issues with importmaps)
import EditorFormController from "./editor_form_controller.js"
pandaCmsApplication.register("editor-form", EditorFormController)

import EditorIframeController from "./editor_iframe_controller.js"
pandaCmsApplication.register("editor-iframe", EditorIframeController)

// Note: Toggle, Slideover, and other TailwindCSS Stimulus Components
// are now registered by Panda Core since the admin layout lives there

console.debug("[Panda CMS] Components registered...")

export { pandaCmsApplication }

console.debug("[Panda CMS] Application exported...")
