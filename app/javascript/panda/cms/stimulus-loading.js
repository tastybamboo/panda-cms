// Stimulus loading utilities for Panda CMS
// This provides the loading functionality that would normally come from stimulus-rails

import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure debug mode based on environment
const railsEnv = document.body?.dataset?.environment || "production";
application.debug = railsEnv === "development"
window.Stimulus = application

// Auto-registration functionality
function eagerLoadControllersFrom(context) {
  const definitions = []
  for (const path of context.keys()) {
    const module = context(path)
    const controller = module.default
    if (controller && path.match(/[_-]controller\.(js|ts)$/)) {
      const name = path
        .replace(/^.*\//, "")
        .replace(/[_-]controller\.(js|ts)$/, "")
        .replace(/_/g, "-")
      definitions.push({ name, module: controller, filename: path })
    }
  }
  return definitions
}

function lazyLoadControllersFrom(context) {
  return eagerLoadControllersFrom(context)
}

// Export the functions that stimulus-loading typically provides
export {
  application,
  eagerLoadControllersFrom,
  lazyLoadControllersFrom
}