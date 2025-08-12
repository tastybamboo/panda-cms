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

// Import and register TailwindCSS Stimulus Components needed by CMS
import { Toggle } from "tailwindcss-stimulus-components"
pandaCmsApplication.register("toggle", Toggle)

console.debug("[Panda CMS] Registered Toggle controller for slideover functionality")

console.debug("[Panda CMS] Components registered...")

export { pandaCmsApplication }

console.debug("[Panda CMS] Application exported...")
