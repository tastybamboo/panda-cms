import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "toggle", "container", "body"]
  static values = {
    collapsed: { type: Array, default: [] },
    childrenUrl: { type: String, default: "" },
    showArchived: { type: String, default: "false" }
  }

  connect() {
    // Mark homepage row as children-loaded (level 1 pages are pre-rendered)
    this.rowTargets.forEach(row => {
      if (parseInt(row.dataset.level) === 0) {
        row.dataset.childrenLoaded = "true"
      }
    })

    // All level 1 pages start collapsed by default
    this.initializeTree()
  }

  initializeTree() {
    this.rowTargets.forEach(row => {
      const level = parseInt(row.dataset.level)
      const pageId = row.dataset.pageId

      if (level === 1) {
        const hasChildren = row.querySelector('[data-tree-target="toggle"]')
        if (hasChildren) {
          this.collapsedValue = [...this.collapsedValue, pageId]
          this.updateToggleIcon(pageId, true)
        }
      }
    })

    this.showTree()
  }

  // Helper to get the actual table row element from our target div
  getTableRow(rowTarget) {
    return rowTarget.closest('.table-row')
  }

  toggle(event) {
    event.preventDefault()
    const row = event.currentTarget.closest('[data-tree-target="row"]')
    const pageId = row.dataset.pageId
    const level = parseInt(row.dataset.level)

    if (this.isCollapsed(pageId)) {
      this.expand(pageId, level, row)
    } else {
      this.collapse(pageId, level)
    }
  }

  collapse(pageId, level) {
    if (!this.collapsedValue.includes(pageId)) {
      this.collapsedValue = [...this.collapsedValue, pageId]
    }

    // Hide all descendant rows currently in the DOM
    const descendants = this.getDescendantRows(pageId, level)
    descendants.forEach(row => {
      const tableRow = this.getTableRow(row)
      if (tableRow) tableRow.style.display = 'none'
    })

    this.updateToggleIcon(pageId, true)
  }

  async expand(pageId, level, row) {
    this.collapsedValue = this.collapsedValue.filter(id => id !== pageId)
    this.updateToggleIcon(pageId, false)

    if (row.dataset.childrenLoaded === "true") {
      // Children already in DOM — just show direct children
      const directChildren = this.getDirectChildRows(pageId, level)
      directChildren.forEach(childRow => {
        const tableRow = this.getTableRow(childRow)
        if (tableRow) tableRow.style.display = ''
      })
    } else {
      // Fetch children from server
      await this.loadChildren(pageId, row)
    }
  }

  async loadChildren(pageId, row) {
    if (!this.childrenUrlValue) return

    const url = this.childrenUrlValue.replace("__ID__", pageId)
    const separator = url.includes("?") ? "&" : "?"
    const fullUrl = `${url}${separator}show_archived=${this.showArchivedValue}`

    // Show loading spinner
    const toggle = row.querySelector('[data-tree-target="toggle"]')
    let originalIcon
    if (toggle) {
      originalIcon = toggle.innerHTML
      toggle.innerHTML = '<i class="fa-solid fa-spinner fa-spin text-xs"></i>'
    }

    try {
      const response = await fetch(fullUrl, {
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const html = await response.text()

      // Insert the rows after the parent's table-row
      const parentTableRow = this.getTableRow(row)
      if (parentTableRow && html.trim()) {
        parentTableRow.insertAdjacentHTML('afterend', html)
      }

      row.dataset.childrenLoaded = "true"

      // Re-register Stimulus targets by dispatching an event
      // (Stimulus auto-detects new targets in the DOM)
    } catch (error) {
      console.error("Failed to load children:", error)
      // Restore collapsed state on error
      if (!this.collapsedValue.includes(pageId)) {
        this.collapsedValue = [...this.collapsedValue, pageId]
      }
    } finally {
      // Restore icon
      if (toggle && originalIcon) {
        this.updateToggleIcon(pageId, this.isCollapsed(pageId))
      }
    }
  }

  getDescendantRows(pageId, parentLevel) {
    const allRows = this.rowTargets
    const parentIndex = allRows.findIndex(row => row.dataset.pageId === pageId)
    const descendants = []

    for (let i = parentIndex + 1; i < allRows.length; i++) {
      const rowLevel = parseInt(allRows[i].dataset.level)
      if (rowLevel <= parentLevel) break
      descendants.push(allRows[i])
    }

    return descendants
  }

  getDirectChildRows(pageId, parentLevel) {
    const allRows = this.rowTargets
    const parentIndex = allRows.findIndex(row => row.dataset.pageId === pageId)
    const children = []

    for (let i = parentIndex + 1; i < allRows.length; i++) {
      const rowLevel = parseInt(allRows[i].dataset.level)
      if (rowLevel <= parentLevel) break
      if (rowLevel === parentLevel + 1) children.push(allRows[i])
    }

    return children
  }

  isCollapsed(pageId) {
    return this.collapsedValue.includes(pageId)
  }

  updateToggleIcon(pageId, collapsed) {
    const row = this.rowTargets.find(r => r.dataset.pageId === pageId)
    if (!row) return

    const toggle = row.querySelector('[data-tree-target="toggle"]')
    if (!toggle) return

    const icon = toggle.querySelector('i')
    if (icon) {
      if (collapsed) {
        icon.classList.remove('fa-chevron-down', 'fa-spinner', 'fa-spin')
        icon.classList.add('fa-chevron-right')
      } else {
        icon.classList.remove('fa-chevron-right', 'fa-spinner', 'fa-spin')
        icon.classList.add('fa-chevron-down')
      }
    }
  }

  showTree() {
    if (this.hasContainerTarget) {
      this.containerTarget.style.opacity = '1'
    }
  }
}
