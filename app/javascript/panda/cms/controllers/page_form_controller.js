import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "inheritCheckbox",
    "pageTitle",
    "seoTitle",
    "seoDescription",
    "seoKeywords",
    "canonicalUrl",
    "ogTitle",
    "ogDescription",
    "ogType",
    "generateButton"
  ]

  static values = {
    parentSeoData: Object,
    pageId: String,
    aiGenerationUrl: String,
    maxSeoTitle: { type: Number, default: 70 },
    maxSeoDescription: { type: Number, default: 160 },
    maxOgTitle: { type: Number, default: 60 },
    maxOgDescription: { type: Number, default: 200 }
  }

  connect() {
    console.log("[Page Form] Controller connected")

    // Initialize character counters
    this.initializeCharacterCounters()

    // Set initial inherit state if checkbox exists
    if (this.hasInheritCheckboxTarget) {
      this.updateInheritState()
    }

    // Add auto-fill listeners
    this.setupAutoFillListeners()

    // Hide AI generation button if URL is not available (cms-pro not installed)
    if (this.hasGenerateButtonTarget && !this.hasAiGenerationUrlValue) {
      this.generateButtonTarget.closest('div').style.display = 'none'
    }
  }

  initializeCharacterCounters() {
    // Add character counters for fields with limits
    const fieldConfigs = [
      { target: "seoTitle", max: this.maxSeoTitleValue, label: "SEO Title" },
      { target: "seoDescription", max: this.maxSeoDescriptionValue, label: "SEO Description" },
      { target: "ogTitle", max: this.maxOgTitleValue, label: "Social Media Title" },
      { target: "ogDescription", max: this.maxOgDescriptionValue, label: "Social Media Description" }
    ]

    fieldConfigs.forEach(config => {
      const targetName = `${config.target}Target`
      if (this[`has${config.target.charAt(0).toUpperCase() + config.target.slice(1)}Target`]) {
        const field = this[targetName]
        this.createCharacterCounter(field, config.max)

        // Update counter on input
        field.addEventListener('input', () => {
          this.updateCharacterCounter(field, config.max)
        })
      }
    })
  }

  createCharacterCounter(field, maxLength) {
    // Find or create counter element
    const container = field.closest('.panda-core-field-container')
    if (!container) return

    let counter = container.querySelector('.character-counter')
    if (!counter) {
      counter = document.createElement('div')
      counter.className = 'character-counter text-xs mt-1 text-gray-500 dark:text-gray-400'

      // Insert after the field but before error messages
      const errorMsg = container.querySelector('.text-red-600')
      if (errorMsg) {
        errorMsg.before(counter)
      } else {
        container.appendChild(counter)
      }
    }

    this.updateCharacterCounter(field, maxLength)
  }

  updateCharacterCounter(field, maxLength) {
    const container = field.closest('.panda-core-field-container')
    if (!container) return

    const counter = container.querySelector('.character-counter')
    if (!counter) return

    const currentLength = field.value.length
    const remaining = maxLength - currentLength

    // Update counter text and styling
    counter.textContent = `${currentLength} / ${maxLength} characters`

    if (remaining < 0) {
      counter.classList.remove('text-gray-500', 'dark:text-gray-400', 'text-yellow-600', 'dark:text-yellow-400')
      counter.classList.add('text-red-600', 'dark:text-red-400', 'font-semibold')
      counter.textContent += ` (${Math.abs(remaining)} over limit)`
    } else if (remaining < 10) {
      counter.classList.remove('text-gray-500', 'dark:text-gray-400', 'text-red-600', 'dark:text-red-400')
      counter.classList.add('text-yellow-600', 'dark:text-yellow-400')
    } else {
      counter.classList.remove('text-red-600', 'dark:text-red-400', 'text-yellow-600', 'dark:text-yellow-400', 'font-semibold')
      counter.classList.add('text-gray-500', 'dark:text-gray-400')
    }
  }

  setupAutoFillListeners() {
    // Initialize auto-fill on connect (for page load)
    this.applyAutoFillDefaults()

    // Auto-fill SEO title from page title on blur
    if (this.hasPageTitleTarget && this.hasSeoTitleTarget) {
      this.pageTitleTarget.addEventListener('blur', () => {
        this.autoFillSeoTitle()
      })
    }

    // Auto-fill OG title from SEO title on blur
    if (this.hasSeoTitleTarget && this.hasOgTitleTarget) {
      this.seoTitleTarget.addEventListener('blur', () => {
        this.autoFillOgTitle()
      })
    }

    // Auto-fill OG description from SEO description on blur
    if (this.hasSeoDescriptionTarget && this.hasOgDescriptionTarget) {
      this.seoDescriptionTarget.addEventListener('blur', () => {
        this.autoFillOgDescription()
      })
    }
  }

  applyAutoFillDefaults() {
    // On page load, set placeholders for empty fields
    if (this.hasSeoTitleTarget && this.hasPageTitleTarget) {
      this.updatePlaceholder(this.seoTitleTarget, this.pageTitleTarget.value)
    }

    if (this.hasOgTitleTarget) {
      const fallback = this.getSeoTitleValue() || this.getPageTitleValue() || ''
      this.updatePlaceholder(this.ogTitleTarget, fallback)
    }

    if (this.hasOgDescriptionTarget && this.hasSeoDescriptionTarget) {
      this.updatePlaceholder(this.ogDescriptionTarget, this.seoDescriptionTarget.value)
    }
  }

  autoFillSeoTitle() {
    if (!this.hasSeoTitleTarget || !this.hasPageTitleTarget) return

    // Only fill if SEO title is empty
    if (this.seoTitleTarget.value.trim() === '') {
      const pageTitle = this.pageTitleTarget.value.trim()
      if (pageTitle) {
        this.seoTitleTarget.value = pageTitle
        this.updateCharacterCounter(this.seoTitleTarget, this.maxSeoTitleValue)
      }
    }
  }

  autoFillOgTitle() {
    if (!this.hasOgTitleTarget) return

    // Only fill if OG title is empty
    if (this.ogTitleTarget.value.trim() === '') {
      const fallback = this.getSeoTitleValue() || this.getPageTitleValue() || ''
      if (fallback) {
        this.ogTitleTarget.value = fallback
        this.updateCharacterCounter(this.ogTitleTarget, this.maxOgTitleValue)
      }
    }
  }

  autoFillOgDescription() {
    if (!this.hasOgDescriptionTarget || !this.hasSeoDescriptionTarget) return

    // Only fill if OG description is empty
    if (this.ogDescriptionTarget.value.trim() === '') {
      const seoDesc = this.seoDescriptionTarget.value.trim()
      if (seoDesc) {
        this.ogDescriptionTarget.value = seoDesc
        this.updateCharacterCounter(this.ogDescriptionTarget, this.maxOgDescriptionValue)
      }
    }
  }

  getPageTitleValue() {
    return this.hasPageTitleTarget ? this.pageTitleTarget.value.trim() : ''
  }

  getSeoTitleValue() {
    return this.hasSeoTitleTarget ? this.seoTitleTarget.value.trim() : ''
  }

  updatePlaceholder(field, value) {
    if (field.value.trim() === '' && value && value.trim() !== '') {
      field.setAttribute('placeholder', value)
    }
  }

  // Handle inherit settings checkbox toggle
  toggleInherit(event) {
    const isChecked = event.target.checked
    console.log(`[Page Form] Inherit settings: ${isChecked}`)

    this.updateInheritState()
  }

  updateInheritState() {
    if (!this.hasInheritCheckboxTarget) return

    const isInheriting = this.inheritCheckboxTarget.checked

    // Get SEO field targets
    const seoFields = [
      'seoTitle',
      'seoDescription',
      'seoKeywords',
      'canonicalUrl',
      'ogTitle',
      'ogDescription',
      'ogType'
    ]

    seoFields.forEach(fieldName => {
      const targetName = `${fieldName}Target`
      const hasTarget = this[`has${fieldName.charAt(0).toUpperCase() + fieldName.slice(1)}Target`]

      if (hasTarget) {
        const field = this[targetName]

        if (isInheriting) {
          // Copy parent values and make readonly
          this.copyParentValue(field, fieldName)
          field.setAttribute('readonly', true)
          field.classList.add('cursor-not-allowed', 'bg-gray-50', 'dark:bg-white/10')
        } else {
          // Make editable
          field.removeAttribute('readonly')
          field.classList.remove('cursor-not-allowed', 'bg-gray-50', 'dark:bg-white/10')
        }
      }
    })
  }

  copyParentValue(field, fieldName) {
    // If we have parent SEO data, use it
    if (this.hasParentSeoDataValue && this.parentSeoDataValue[fieldName]) {
      field.value = this.parentSeoDataValue[fieldName]

      // Update character counter if it exists
      const maxValue = this[`max${fieldName.charAt(0).toUpperCase() + fieldName.slice(1)}Value`]
      if (maxValue) {
        this.updateCharacterCounter(field, maxValue)
      }
    }
  }

  // Validate form before submission
  validateForm(event) {
    let isValid = true
    const errors = []

    // Check SEO title length
    if (this.hasSeoTitleTarget && this.seoTitleTarget.value.length > this.maxSeoTitleValue) {
      errors.push(`SEO Title is ${this.seoTitleTarget.value.length - this.maxSeoTitleValue} characters over the ${this.maxSeoTitleValue} character limit`)
      isValid = false
    }

    // Check SEO description length
    if (this.hasSeoDescriptionTarget && this.seoDescriptionTarget.value.length > this.maxSeoDescriptionValue) {
      errors.push(`SEO Description is ${this.seoDescriptionTarget.value.length - this.maxSeoDescriptionValue} characters over the ${this.maxSeoDescriptionValue} character limit`)
      isValid = false
    }

    // Check OG title length
    if (this.hasOgTitleTarget && this.ogTitleTarget.value.length > this.maxOgTitleValue) {
      errors.push(`Social Media Title is ${this.ogTitleTarget.value.length - this.maxOgTitleValue} characters over the ${this.maxOgTitleValue} character limit`)
      isValid = false
    }

    // Check OG description length
    if (this.hasOgDescriptionTarget && this.ogDescriptionTarget.value.length > this.maxOgDescriptionValue) {
      errors.push(`Social Media Description is ${this.ogDescriptionTarget.value.length - this.maxOgDescriptionValue} characters over the ${this.maxOgDescriptionValue} character limit`)
      isValid = false
    }

    if (!isValid) {
      // Show validation errors
      const errorMessage = errors.join('\n')

      // If we can prevent form submission, do so and show errors
      if (event && event.preventDefault) {
        event.preventDefault()
        alert(`Please fix the following errors:\n\n${errorMessage}`)
      }

      return false
    }

    return true
  }

  // Generate SEO content using AI
  async generateSeoWithAI() {
    if (!this.hasAiGenerationUrlValue) {
      console.error("[Page Form] No AI generation URL available")
      this.showError("AI generation is not available. Please ensure panda-cms-pro is installed and configured.")
      return
    }

    // Get CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (!csrfToken) {
      console.error("[Page Form] CSRF token not found")
      this.showError("Security token not found. Please refresh the page.")
      return
    }

    // Disable button and show loading state
    const button = this.hasGenerateButtonTarget ? this.generateButtonTarget : null
    const originalButtonText = button?.innerHTML || ""

    if (button) {
      button.disabled = true
      button.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Generating...'
    }

    try {
      // Make API request using the URL from Rails
      const response = await fetch(this.aiGenerationUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json'
        }
      })

      const data = await response.json()

      if (response.ok && data.success) {
        // Fill in the generated SEO fields
        this.fillGeneratedFields(data)
        this.showSuccess(`SEO content generated successfully using ${data.provider} (${data.model})`)
      } else {
        // Handle errors from the API
        const errorMessage = data.message || "Failed to generate SEO content"

        if (data.error === 'no_provider') {
          this.showError("No AI provider configured. Please configure an AI provider in settings.")
        } else {
          this.showError(errorMessage)
        }
      }
    } catch (error) {
      console.error("[Page Form] AI generation error:", error)
      this.showError("Failed to connect to AI service. Please try again.")
    } finally {
      // Re-enable button
      if (button) {
        button.disabled = false
        button.innerHTML = originalButtonText
      }
    }
  }

  fillGeneratedFields(data) {
    // Fill SEO fields with generated content
    if (data.seo_title && this.hasSeoTitleTarget) {
      this.seoTitleTarget.value = data.seo_title
      this.updateCharacterCounter(this.seoTitleTarget, this.maxSeoTitleValue)
    }

    if (data.seo_description && this.hasSeoDescriptionTarget) {
      this.seoDescriptionTarget.value = data.seo_description
      this.updateCharacterCounter(this.seoDescriptionTarget, this.maxSeoDescriptionValue)
    }

    if (data.seo_keywords && this.hasSeoKeywordsTarget) {
      this.seoKeywordsTarget.value = data.seo_keywords
    }

    if (data.og_title && this.hasOgTitleTarget) {
      this.ogTitleTarget.value = data.og_title
      this.updateCharacterCounter(this.ogTitleTarget, this.maxOgTitleValue)
    }

    if (data.og_description && this.hasOgDescriptionTarget) {
      this.ogDescriptionTarget.value = data.og_description
      this.updateCharacterCounter(this.ogDescriptionTarget, this.maxOgDescriptionValue)
    }

    console.log("[Page Form] Successfully filled AI-generated SEO fields")
  }

  showSuccess(message) {
    // Find or create success message element
    const successEl = document.getElementById('successMessage')
    if (successEl) {
      const messageContainer = successEl.querySelector('[role="alert"]')
      if (messageContainer) {
        const messageText = messageContainer.querySelector('p')
        if (messageText) {
          messageText.textContent = message
        }
      }
      successEl.classList.remove('hidden')

      // Auto-hide after 5 seconds
      setTimeout(() => {
        successEl.classList.add('hidden')
      }, 5000)
    } else {
      // Fallback to alert if flash message component not found
      alert(message)
    }
  }

  showError(message) {
    // Find or create error message element
    const errorEl = document.getElementById('errorMessage')
    if (errorEl) {
      const messageContainer = errorEl.querySelector('[role="alert"]')
      if (messageContainer) {
        const messageText = messageContainer.querySelector('p')
        if (messageText) {
          messageText.textContent = message
        }
      }
      errorEl.classList.remove('hidden')

      // Auto-hide after 8 seconds
      setTimeout(() => {
        errorEl.classList.add('hidden')
      }, 8000)
    } else {
      // Fallback to alert if flash message component not found
      alert(message)
    }
  }
}
