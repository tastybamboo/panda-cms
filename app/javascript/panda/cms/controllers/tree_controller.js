import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "toggle", "container"]
  static values = {
    collapsed: { type: Array, default: [] }
  }

  connect() {
    const hasStoredState = localStorage.getItem('panda-cms-pages-collapsed')

    if (hasStoredState) {
      this.loadCollapsedState()
    } else {
      this.initializeTree()
    }
  }

  // Helper to get the actual table row element from our target div
  getTableRow(rowTarget) {
    return rowTarget.closest('.table-row')
  }

  initializeTree() {
    // Collapse all level 1 pages (direct children of Home) by default
    this.rowTargets.forEach(row => {
      const level = parseInt(row.dataset.level)
      const pageId = row.dataset.pageId

      // If it's a level 1 page with children, mark it as collapsed
      if (level === 1) {
        const hasChildren = row.querySelector('[data-tree-target="toggle"]')
        if (hasChildren) {
          this.collapsedValue = [...this.collapsedValue, pageId]
          this.updateToggleIcon(pageId, true)
        }
      }

      // Hide everything below level 1 (level > 1)
      if (level > 1) {
        const tableRow = this.getTableRow(row)
        if (tableRow) tableRow.style.display = 'none'
      }
    })

    // Save the initial collapsed state
    this.saveCollapsedState()

    // Fade in the tree after initialization
    this.showTree()
  }

  toggle(event) {
    event.preventDefault()
    const row = event.currentTarget.closest('[data-tree-target="row"]')
    const pageId = row.dataset.pageId
    const level = parseInt(row.dataset.level)

    if (this.isCollapsed(pageId)) {
      this.expand(pageId, level)
    } else {
      this.collapse(pageId, level)
    }

    this.saveCollapsedState()
  }

  collapse(pageId, level) {
    // Add to collapsed set
    if (!this.collapsedValue.includes(pageId)) {
      this.collapsedValue = [...this.collapsedValue, pageId]
    }

    // Hide all descendant rows
    const descendants = this.getDescendantRows(pageId, level)
    descendants.forEach(row => {
      const tableRow = this.getTableRow(row)
      if (tableRow) {
        tableRow.style.display = 'none'
      }
    })

    // Update toggle icon
    this.updateToggleIcon(pageId, true)
  }

  expand(pageId, level) {
    // Remove from collapsed set
    this.collapsedValue = this.collapsedValue.filter(id => id !== pageId)

    // Show direct children only (they will handle their own children)
    const directChildren = this.getDirectChildRows(pageId, level)
    directChildren.forEach(row => {
      const tableRow = this.getTableRow(row)
      if (tableRow) tableRow.style.display = ''
    })

    // Update toggle icon
    this.updateToggleIcon(pageId, false)
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
        icon.classList.remove('fa-chevron-down')
        icon.classList.add('fa-chevron-right')
      } else {
        icon.classList.remove('fa-chevron-right')
        icon.classList.add('fa-chevron-down')
      }
    }
  }

  loadCollapsedState() {
    try {
      const stored = localStorage.getItem('panda-cms-pages-collapsed')
      if (stored) {
        this.collapsedValue = JSON.parse(stored)

        // First, show all pages at level 1 (direct children of Home)
        this.rowTargets.forEach(row => {
          const level = parseInt(row.dataset.level)
          if (level === 1) {
            const tableRow = this.getTableRow(row)
            if (tableRow) tableRow.style.display = ''
          }
        })

        // Then apply collapsed state - hiding descendants of collapsed items
        this.collapsedValue.forEach(pageId => {
          const row = this.rowTargets.find(r => r.dataset.pageId === pageId)
          if (row) {
            const level = parseInt(row.dataset.level)
            this.collapse(pageId, level)
          }
        })

        // For level 1 items NOT in collapsed list, show their children
        this.rowTargets.forEach(row => {
          const level = parseInt(row.dataset.level)
          const pageId = row.dataset.pageId
          const hasToggle = row.querySelector('[data-tree-target="toggle"]')

          if (level === 1 && hasToggle && !this.isCollapsed(pageId)) {
            // This level 1 item is expanded, show its direct children
            this.getDirectChildRows(pageId, level).forEach(childRow => {
              const tableRow = this.getTableRow(childRow)
              if (tableRow) tableRow.style.display = ''
            })
          }
        })

        // Fade in the tree after loading state
        this.showTree()
      }
    } catch (e) {
      console.error('Error loading collapsed state:', e)
    }
  }

  showTree() {
    // Fade in the container
    if (this.hasContainerTarget) {
      this.containerTarget.style.opacity = '1'
    }
  }

  saveCollapsedState() {
    try {
      localStorage.setItem('panda-cms-pages-collapsed', JSON.stringify(this.collapsedValue))
    } catch (e) {
      console.error('Error saving collapsed state:', e)
    }
  }
}
