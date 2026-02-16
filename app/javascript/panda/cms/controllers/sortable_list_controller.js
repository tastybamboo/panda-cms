import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.dragItem = null
    this.form = this.element.closest("form")
    if (this.form) {
      this.boundUpdatePositions = this.updatePositions.bind(this)
      this.form.addEventListener("submit", this.boundUpdatePositions)
    }
  }

  disconnect() {
    if (this.form && this.boundUpdatePositions) {
      this.form.removeEventListener("submit", this.boundUpdatePositions)
    }
  }

  itemTargetConnected(item) {
    this.setupDragEvents(item)
    this.updatePositions()
  }

  itemTargetDisconnected(item) {
    const handlers = item._sortableHandlers
    if (!handlers) return

    handlers.handle.removeEventListener("mousedown", handlers.onMouseDown)
    item.removeEventListener("dragstart", handlers.onDragStart)
    item.removeEventListener("dragover", handlers.onDragOver)
    item.removeEventListener("dragend", handlers.onDragEnd)
    item.removeEventListener("drop", handlers.onDrop)
    delete item._sortableHandlers
  }

  setupDragEvents(item) {
    const handle = item.querySelector("[data-sortable-handle]")
    if (!handle) return

    const onMouseDown = () => {
      item.setAttribute("draggable", "true")
      document.addEventListener("mouseup", () => {
        if (!this.dragItem) item.removeAttribute("draggable")
      }, { once: true })
    }
    const onDragStart = (e) => this.onDragStart(e, item)
    const onDragOver = (e) => this.onDragOver(e)
    const onDragEnd = (e) => this.onDragEnd(e, item)
    const onDrop = (e) => e.preventDefault()

    handle.addEventListener("mousedown", onMouseDown)
    item.addEventListener("dragstart", onDragStart)
    item.addEventListener("dragover", onDragOver)
    item.addEventListener("dragend", onDragEnd)
    item.addEventListener("drop", onDrop)

    item._sortableHandlers = { handle, onMouseDown, onDragStart, onDragOver, onDragEnd, onDrop }
  }

  onDragStart(event, item) {
    this.dragItem = item
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", "")

    requestAnimationFrame(() => {
      item.classList.add("opacity-50", "border-dashed", "border-blue-300")
    })
  }

  onDragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    if (!this.dragItem) return

    const target = event.target.closest("[data-sortable-list-target='item']")
    if (!target || target === this.dragItem || target.style.display === "none") return

    const rect = target.getBoundingClientRect()
    const midY = rect.top + rect.height / 2

    if (event.clientY < midY) {
      target.parentNode.insertBefore(this.dragItem, target)
    } else {
      target.parentNode.insertBefore(this.dragItem, target.nextSibling)
    }
  }

  onDragEnd(event, item) {
    item.classList.remove("opacity-50", "border-dashed", "border-blue-300")
    item.removeAttribute("draggable")
    this.dragItem = null
    this.updatePositions()
  }

  updatePositions() {
    let position = 0
    this.itemTargets.forEach((item) => {
      if (item.style.display === "none") return

      const positionInput = item.querySelector("input[name*='[position]']")
      if (positionInput) {
        positionInput.value = position
        position++
      }
    })
  }
}
