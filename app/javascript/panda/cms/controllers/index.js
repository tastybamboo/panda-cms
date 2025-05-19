console.debug("[Panda CMS] Importing Panda CMS Stimulus Controller...")

import { Application as PandaCMSApplication } from "@hotwired/stimulus"

const pandaCmsApplication = PandaCMSApplication.start()

console.debug("[Panda CMS] Application started...")

// Configure Stimulus development experience
pandaCmsApplication.debug = false
window.pandaCmsStimulus = pandaCmsApplication

console.debug("[Panda CMS] window.pandaCmsStimulus available...")

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

console.debug("[Panda CMS] Registering components...")
import ThemeFormController from "panda/cms/controllers/theme_form_controller";
pandaCmsApplication.register("theme-form", ThemeFormController);

// Import and register all TailwindCSS Components or just the ones you need
import { Alert, Autosave, ColorPreview, Dropdown, Modal, Tabs, Popover, Toggle, Slideover } from "tailwindcss-stimulus-components"
pandaCmsApplication.register('alert', Alert)
pandaCmsApplication.register('autosave', Autosave)
pandaCmsApplication.register('color-preview', ColorPreview)
pandaCmsApplication.register('dropdown', Dropdown)
pandaCmsApplication.register('modal', Modal)
pandaCmsApplication.register('popover', Popover)
pandaCmsApplication.register('slideover', Slideover)
pandaCmsApplication.register('tabs', Tabs)
pandaCmsApplication.register('toggle', Toggle)

console.debug("[Panda CMS] Components registered...")

export { pandaCmsApplication }

console.debug("[Panda CMS] Application exported...")
