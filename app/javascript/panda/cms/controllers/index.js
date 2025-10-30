console.debug("[Panda CMS] Importing Panda CMS Stimulus Controller...")

import { application } from "@hotwired/stimulus-loading"

console.debug("[Panda CMS] Using shared Stimulus application...")

const pandaCmsApplication = application

console.debug("[Panda CMS] Registering controllers...")

// Use the same paths as defined in _importmap.html.erb
import DashboardController from "panda/cms/controllers/dashboard_controller"
pandaCmsApplication.register("dashboard", DashboardController)

import EditorFormController from "panda/cms/controllers/editor_form_controller"
pandaCmsApplication.register("editor-form", EditorFormController)

import SlugController from "panda/cms/controllers/slug_controller"
pandaCmsApplication.register("slug", SlugController)

import EditorIframeController from "panda/cms/controllers/editor_iframe_controller"
pandaCmsApplication.register("editor-iframe", EditorIframeController)

// Note: Toggle, Slideover, and other TailwindCSS Stimulus Components
// are now registered by Panda Core since the admin layout lives there

console.debug("[Panda CMS] Components registered...")

export { pandaCmsApplication }

console.debug("[Panda CMS] Application exported...")
