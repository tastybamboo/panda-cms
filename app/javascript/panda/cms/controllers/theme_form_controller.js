import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="theme-form"
export default class extends Controller {
  connect() {
    // Ensure submit button is enabled on connect
    this.enableSubmitButton();
  }

  updateTheme(event) {
    const newTheme = event.target.value;
    document.documentElement.dataset.theme = newTheme;
  }

  enableSubmitButton() {
    // Find the submit button in the form and ensure it's enabled
    const form = this.element;
    if (form) {
      const submitButton = form.querySelector('input[type="submit"], button[type="submit"]');
      if (submitButton) {
        submitButton.disabled = false;
      }
    }
  }
}
