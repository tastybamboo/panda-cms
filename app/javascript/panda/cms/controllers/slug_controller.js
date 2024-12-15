import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "existing_root",
    "input_select",
    "input_text",
    "output_text",
  ];

  connect() {
    console.debug("[Panda CMS] Slug handler connected...");
    // Generate path on initial load if title exists
    if (this.input_textTarget.value) {
      this.generatePath();
    }
  }

  generatePath() {
    try {
      const slug = this.createSlug(this.input_textTarget.value);
      // For posts, we want to store just the slug part
      const prefix = this.output_textTarget.dataset.prefix || "";
      this.output_textTarget.value = "/" + slug;

      // If there's a prefix, show it in the UI but don't include it in the value
      if (prefix) {
        const prefixSpan = this.output_textTarget.previousElementSibling ||
          (() => {
            const span = document.createElement('span');
            span.className = 'prefix';
            this.output_textTarget.parentNode.insertBefore(span, this.output_textTarget);
            return span;
          })();
        prefixSpan.textContent = prefix;
      }

      console.log("Have set the path to: " + this.output_textTarget.value);
    } catch (error) {
      console.error("Error generating path:", error);
      // Add error class to path field
      this.output_textTarget.classList.add("error");
    }
  }

  setPrePath() {
    try {
      const match = this.input_selectTarget.options[this.input_selectTarget.selectedIndex].text.match(/.*\((.*)\)$/);
      if (match) {
        this.parent_slugs = match[1];
        const prePath = (this.existing_rootTarget.value + this.parent_slugs).replace(/\/$/, "");
        const prefixSpan = this.output_textTarget.previousElementSibling;
        if (prefixSpan) {
          prefixSpan.textContent = prePath;
        }
        console.log("Have set the pre-path to: " + prePath);
      }
    } catch (error) {
      console.error("Error setting pre-path:", error);
    }
  }

  // TODO: Invoke a library or helper which can be shared with the backend
  // and check for uniqueness at the same time
  createSlug(input) {
    if (!input) return "";

    var str = input
      .toLowerCase()
      .trim()
      .replace(/[^\w\s-]/g, "-")
      .replace(/&/g, "and")
      .replace(/[\s_-]+/g, "-")
      .trim();

    return this.trimStartEnd(str, "-");
  }

  trimStartEnd(str, ch) {
    var start = 0;
    var end = str.length;

    while (start < end && str[start] === ch) ++start;
    while (end > start && str[end - 1] === ch) --end;
    return start > 0 || end < str.length ? str.substring(start, end) : str;
  }
}
