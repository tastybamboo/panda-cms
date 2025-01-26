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
    // Don't auto-generate on connect anymore
  }

  generatePath() {
    const title = this.input_textTarget.value.trim();
    console.debug("[Panda CMS] Generating path from title:", title);

    if (!title) {
      this.output_textTarget.value = "";
      return;
    }

    // Only generate path if output is empty AND user has not manually edited it
    if (!this.output_textTarget.value && !this.output_textTarget.dataset.userEdited) {
      // Convert title to slug format
      const slug = this.createSlug(title);
      console.debug("[Panda CMS] Generated slug:", slug);

      // Only add year/month prefix for posts
      if (this.addDatePrefixValue) {
        // Get current date for year/month
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, "0");

        // Add leading slash and use date format
        this.output_textTarget.value = `/${year}/${month}/${slug}`;
      } else {
        // If we have a parent selected, let setPrePath handle it
        if (this.input_selectTarget.value) {
          this.setPrePath(slug);
        } else {
          // Add leading slash for regular pages
          this.output_textTarget.value = `/${slug}`;
        }
      }
      console.debug("[Panda CMS] Final path value:", this.output_textTarget.value);
    }
  }

  setPrePath(slug = null) {
    try {
      const match = this.input_selectTarget.options[this.input_selectTarget.selectedIndex].text.match(/.*\((.*)\)$/);
      if (match) {
        const parentPath = match[1].replace(/\/$/, ""); // Remove trailing slash if present
        const currentSlug = slug || (this.input_textTarget.value ? this.createSlug(this.input_textTarget.value.trim()) : "");

        // Set the full path including parent path
        this.output_textTarget.value = currentSlug
          ? `${parentPath}/${currentSlug}`
          : `${parentPath}/`;

        console.debug("[Panda CMS] Set path with parent:", this.output_textTarget.value);
      }
    } catch (e) {
      console.error("[Panda CMS] Error setting pre-path:", e);
    }
  }

  createSlug(input) {
    if (!input || typeof input !== 'string') return "";
    const slug = input
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");
    return slug;
  }

  trimStartEnd(str, ch) {
    let start = 0,
      end = str.length;
    while (start < end && str[start] === ch) ++start;
    while (end > start && str[end - 1] === ch) --end;
    return start > 0 || end < str.length ? str.substring(start, end) : str;
  }

  // Add handler for manual path edits
  handlePathInput() {
    this.output_textTarget.dataset.userEdited = "true";
  }
}
