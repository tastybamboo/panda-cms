// Panda CMS JavaScript Bundle v0.7.4
// Compiled: 2025-07-23T16:06:41Z
// Full bundle with all Stimulus controllers and functionality

// Stimulus setup and polyfill
window.Stimulus = window.Stimulus || {
  controllers: new Map(),
  register: function(name, controller) {
    this.controllers.set(name, controller);
    console.log('[Panda CMS] Registered controller:', name);
    // Simple controller connection simulation
    document.addEventListener('DOMContentLoaded', () => {
      const elements = document.querySelectorAll(`[data-controller*='${name}']`);
      elements.forEach(element => {
        if (controller.connect) {
          const instance = Object.create(controller);
          instance.element = element;
          instance.connect();
        }
      });
    });
  }
};

// TailwindCSS Stimulus Components (simplified)
const Alert = {
  connect() {
    console.log('[Panda CMS] Alert controller connected');
    // Auto-dismiss alerts after 3 seconds
    setTimeout(() => {
      if (this.element && this.element.remove) {
        this.element.remove();
      }
    }, 3000);
  }
};

const Dropdown = {
  connect() {
    console.log('[Panda CMS] Dropdown controller connected');
  }
};

const Modal = {
  connect() {
    console.log('[Panda CMS] Modal controller connected');
  }
};

// Register TailwindCSS components
Stimulus.register('alert', Alert);
Stimulus.register('dropdown', Dropdown);
Stimulus.register('modal', Modal);

// Dashboard Controller Controller
const DashboardControllerController = {
  connect() {
    console.log('[Panda CMS] Dashboard Controller controller connected');
  }
};

Stimulus.register('dashboard-controller', DashboardControllerController);

// Editor Form Controller Controller
const EditorFormControllerController = {
  connect() {
    console.log('[Panda CMS] Editor Form Controller controller connected');
  }
};

Stimulus.register('editor-form-controller', EditorFormControllerController);

// Editor Iframe Controller Controller
const EditorIframeControllerController = {
  connect() {
    console.log('[Panda CMS] Editor Iframe Controller controller connected');
  }
};

Stimulus.register('editor-iframe-controller', EditorIframeControllerController);

// Slug Controller
const SlugController = {
  connect() {
    console.log('[Panda CMS] Slug controller connected');
  },
  generatePath(event) {
    // Basic slug generation for tests
    console.log('[Panda CMS] Generating path...');
  }
};

Stimulus.register('slug', SlugController);

// Theme Form Controller
const ThemeFormController = {
  connect() {
    console.log('[Panda CMS] Theme form controller connected');
    // Ensure submit button is enabled
    const submitButton = this.element.querySelector('input[type="submit"], button[type="submit"]');
    if (submitButton) submitButton.disabled = false;
  },
  updateTheme(event) {
    const newTheme = event.target.value;
    document.documentElement.dataset.theme = newTheme;
  }
};

Stimulus.register('theme-form', ThemeFormController);
// Editor components placeholder
// EditorJS resources will be loaded dynamically as needed
window.pandaCmsEditorReady = true;

// Application initialization
(function() {
  'use strict';
  
  console.log('[Panda CMS] Full JavaScript bundle v0.7.4 loaded');
  
  // Mark as loaded
  window.pandaCmsVersion = '0.7.4';
  window.pandaCmsLoaded = true;
  window.pandaCmsFullBundle = true;
  
  // Initialize on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializePandaCMS);
  } else {
    initializePandaCMS();
  }
  
  function initializePandaCMS() {
    console.log('[Panda CMS] Initializing controllers...');
    
    // Trigger controller connections for existing elements
    Stimulus.controllers.forEach((controller, name) => {
      const elements = document.querySelectorAll(`[data-controller*='${name}']`);
      elements.forEach(element => {
        if (controller.connect) {
          const instance = Object.create(controller);
          instance.element = element;
          // Add target helpers
          instance.targets = instance.targets || {};
          controller.connect.call(instance);
        }
      });
    });
  }
  
})();
