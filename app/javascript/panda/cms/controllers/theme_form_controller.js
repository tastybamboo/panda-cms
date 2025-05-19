import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="theme-form"
export default class extends Controller {
  updateTheme(event) {
    const newTheme = event.target.value;
    document.documentElement.dataset.theme = newTheme;
  }
}
