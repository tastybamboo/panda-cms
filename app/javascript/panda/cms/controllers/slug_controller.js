import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "existing_root",
    "input_select",
    "input_text",
    "output_text",
  ];

  static values = {
    addDatePrefix: { type: Boolean, default: false }
  }

  connect() {
    console.debug("[Panda CMS] Slug handler connected...");
    // Generate path on initial load if title exists
    if (this.input_textTarget.value) {
      this.generatePath();
    }
  }

  generatePath() {
    const title = this.input_textTarget.value;
    if (!title) return;

    // Convert title to slug format
    const slug = title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");

    // Only add year/month prefix for posts
    if (this.addDatePrefixValue) {
      // Get current date for year/month
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      this.output_textTarget.value = `/${year}/${month}/${slug}`;
    } else {
      this.output_textTarget.value = `/${slug}`;
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
