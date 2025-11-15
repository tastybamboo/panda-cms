import "@hotwired/turbo"
console.debug("[Panda CMS] Controllers loading...");
import "./controllers/index.js"
console.debug("[Panda CMS] Controllers loaded...");

// Mark that Panda CMS JavaScript has loaded
window.pandaCmsLoaded = true
console.debug("[Panda CMS] Ready!");

// Editor resources are now handled by panda-editor gem
// The panda-editor gem will load its own resources when needed
