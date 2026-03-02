import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dateField", "timeField", "combinedField"]

  connect() {
    const existing = this.combinedFieldTarget.value
    if (existing) {
      const date = new Date(existing)
      if (!isNaN(date)) {
        this.dateFieldTarget.value = this.formatDate(date)
        this.timeFieldTarget.value = this.formatTime(date)
      }
    }
  }

  update() {
    const date = this.dateFieldTarget.value
    const time = this.timeFieldTarget.value

    if (date && time) {
      this.combinedFieldTarget.value = `${date}T${time}:00`
    } else if (date) {
      this.combinedFieldTarget.value = `${date}T00:00:00`
    } else {
      this.combinedFieldTarget.value = ""
    }
  }

  formatDate(date) {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, "0")
    const d = String(date.getDate()).padStart(2, "0")
    return `${y}-${m}-${d}`
  }

  formatTime(date) {
    const h = String(date.getHours()).padStart(2, "0")
    const m = String(date.getMinutes()).padStart(2, "0")
    return `${h}:${m}`
  }
}
