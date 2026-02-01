import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "hiddenField"]
  static values = {
    penColor: { type: String, default: "black" },
    backgroundColor: { type: String, default: "rgb(255,255,255)" },
    required: { type: Boolean, default: false }
  }

  async connect() {
    try {
      const { default: SignaturePad } = await import("https://esm.sh/signature_pad@5.0.4")

      this.pad = new SignaturePad(this.canvasTarget, {
        penColor: this.penColorValue,
        backgroundColor: this.backgroundColorValue
      })

      this.resizeCanvas()

      this.resizeObserver = new ResizeObserver(() => this.resizeCanvas())
      this.resizeObserver.observe(this.canvasTarget.parentElement)

      this.form = this.element.closest("form")
      if (this.form) {
        this.submitHandler = (event) => this.save(event)
        this.form.addEventListener("submit", this.submitHandler)
      }
    } catch (error) {
      console.error("[Panda CMS] Failed to load signature_pad library:", error.message)
      this.canvasTarget.insertAdjacentHTML("afterend",
        '<p class="text-sm text-red-600 mt-1">Signature pad could not be loaded. Please reload the page.</p>'
      )
      this.canvasTarget.style.display = "none"
    }
  }

  disconnect() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }

    if (this.form && this.submitHandler) {
      this.form.removeEventListener("submit", this.submitHandler)
    }

    if (this.pad) {
      this.pad.off()
    }
  }

  resizeCanvas() {
    if (!this.pad) return

    const canvas = this.canvasTarget
    const ratio = Math.max(window.devicePixelRatio || 1, 1)
    const width = canvas.offsetWidth
    const height = canvas.offsetHeight

    const data = this.pad.isEmpty() ? null : this.pad.toData()

    canvas.width = width * ratio
    canvas.height = height * ratio
    canvas.getContext("2d").scale(ratio, ratio)

    if (data) {
      this.pad.fromData(data)
    } else {
      this.pad.clear()
    }
  }

  clear() {
    if (!this.pad) return

    this.pad.clear()
    this.hiddenFieldTarget.value = ""
    this.hiddenFieldTarget.setCustomValidity("")
  }

  save(event) {
    if (!this.pad) return

    if (this.pad.isEmpty()) {
      if (this.requiredValue) {
        this.hiddenFieldTarget.setCustomValidity("Please provide a signature")
        this.hiddenFieldTarget.reportValidity()
        event.preventDefault()
        return
      }
      this.hiddenFieldTarget.value = ""
    } else {
      this.hiddenFieldTarget.setCustomValidity("")
      this.hiddenFieldTarget.value = this.pad.toDataURL("image/png")
    }
  }
}
