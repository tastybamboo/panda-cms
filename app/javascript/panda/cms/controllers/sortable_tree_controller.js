import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row"]
  static values = { reorderUrl: String }

  connect() {
    this.dragItem = null
    this.dropIndicator = null
  }

  disconnect() {
    this.removeDropIndicator()
  }

  rowTargetConnected(row) {
    this.setupRowDrag(row)
  }

  setupRowDrag(row) {
    const handle = row.querySelector("[data-sortable-tree-handle]")
    if (!handle) return

    const tableRow = row.closest(".table-row")
    if (!tableRow) return

    const onMouseDown = (e) => {
      e.stopPropagation()
      tableRow.setAttribute("draggable", "true")
      document.addEventListener("mouseup", () => {
        if (!this.dragItem) tableRow.removeAttribute("draggable")
      }, { once: true })
    }

    const onDragStart = (e) => {
      this.dragItem = row
      this.dragTableRow = tableRow
      e.dataTransfer.effectAllowed = "move"
      e.dataTransfer.setData("text/plain", "")

      requestAnimationFrame(() => {
        tableRow.classList.add("opacity-50")
      })
    }

    const onDragEnd = () => {
      if (this.dragTableRow) {
        this.dragTableRow.classList.remove("opacity-50")
        this.dragTableRow.removeAttribute("draggable")
      }
      this.dragItem = null
      this.dragTableRow = null
      this.removeDropIndicator()
    }

    handle.addEventListener("mousedown", onMouseDown)
    tableRow.addEventListener("dragstart", onDragStart)
    tableRow.addEventListener("dragend", onDragEnd)
    tableRow.addEventListener("dragover", (e) => this.onDragOver(e, row, tableRow))
    tableRow.addEventListener("drop", (e) => this.onDrop(e, row))
  }

  onDragOver(event, targetRow, targetTableRow) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    if (!this.dragItem || targetRow === this.dragItem) {
      this.removeDropIndicator()
      return
    }

    // Only allow reordering between siblings (same parent, same level)
    if (targetRow.dataset.parentId !== this.dragItem.dataset.parentId) {
      this.removeDropIndicator()
      return
    }

    const rect = targetTableRow.getBoundingClientRect()
    const midY = rect.top + rect.height / 2
    const position = event.clientY < midY ? "before" : "after"

    this.showDropIndicator(targetTableRow, position)
  }

  onDrop(event, targetRow) {
    event.preventDefault()
    if (!this.dragItem || targetRow === this.dragItem) return
    if (targetRow.dataset.parentId !== this.dragItem.dataset.parentId) return

    const targetTableRow = targetRow.closest(".table-row")
    if (!targetTableRow) return

    const rect = targetTableRow.getBoundingClientRect()
    const midY = rect.top + rect.height / 2
    const position = event.clientY < midY ? "before" : "after"

    const pageId = this.dragItem.dataset.pageId
    const targetId = targetRow.dataset.pageId
    const url = this.reorderUrlValue.replace("__PAGE_ID__", pageId)

    this.removeDropIndicator()

    // Send to server, then reload to reflect correct tree order (including descendants)
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: JSON.stringify({ target_id: targetId, position: position })
    }).then(() => {
      window.location.reload()
    }).catch(() => {
      window.location.reload()
    })
  }

  showDropIndicator(targetTableRow, position) {
    this.removeDropIndicator()

    this.dropIndicator = document.createElement("div")
    this.dropIndicator.className = "h-0.5 bg-blue-500 rounded-full mx-2"
    this.dropIndicator.style.pointerEvents = "none"

    if (position === "before") {
      targetTableRow.parentNode.insertBefore(this.dropIndicator, targetTableRow)
    } else {
      targetTableRow.parentNode.insertBefore(this.dropIndicator, targetTableRow.nextSibling)
    }
  }

  removeDropIndicator() {
    if (this.dropIndicator) {
      this.dropIndicator.remove()
      this.dropIndicator = null
    }
  }
}
