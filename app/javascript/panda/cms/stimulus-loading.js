// Stimulus loading utilities for Panda CMS
// This provides the loading functionality that would normally come from stimulus-rails

// Import the shared Stimulus application from Panda Core
// This ensures all controllers (Core and CMS) are registered in the same application
import { application } from "/panda/core/application.js"

// The application is already started and configured in Core
// No need to start it again or configure debug mode

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