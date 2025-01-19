export class ResourceLoader {
  static loadedResources = new Set()

  /**
   * Embeds CSS styles into the document head.
   *
   * @param {Document} frameDocument - The document object to create elements in
   * @param {HTMLElement} head - The head element to append styles to
   * @param {string} css - The CSS styles to embed
   * @returns {Promise} A promise that resolves when the styles are embedded
   */
  static embedCSS(frameDocument, head, css) {
    const cssHash = this.hashString(css)
    if (this.loadedResources.has(`css:${cssHash}`)) {
      console.debug("[Panda CMS] CSS already embedded, skipping")
      return Promise.resolve()
    }

    return new Promise((resolve) => {
      const style = frameDocument.createElement("style")
      style.textContent = css
      head.append(style)
      this.loadedResources.add(`css:${cssHash}`)
      resolve(style)
      console.debug("[Panda CMS] Embedded CSS styles")
    })
  }

  /**
   * Loads a script from a URL and appends it to the document head.
   *
   * @param {Document} frameDocument - The document object to create elements in
   * @param {HTMLElement} head - The head element to append the script to
   * @param {string} src - The URL of the script to load
   * @returns {Promise} A promise that resolves when the script is loaded
   */
  static loadScript(frameDocument, head, src) {
    if (this.loadedResources.has(`script:${src}`)) {
      console.debug(`[Panda CMS] Script already loaded: ${src}, skipping`)
      return Promise.resolve()
    }

    return new Promise((resolve, reject) => {
      const script = frameDocument.createElement("script")
      script.src = src
      script.onload = () => {
        this.loadedResources.add(`script:${src}`)
        resolve(script)
        console.debug(`[Panda CMS] Script loaded: ${src}`)
      }
      script.onerror = () => reject(new Error(`[Panda CMS] Script load error for ${src}`))
      head.append(script)
    })
  }

  static importScript(frameDocument, head, module, src) {
    const key = `module:${module}:${src}`
    if (this.loadedResources.has(key)) {
      console.debug(`[Panda CMS] Module already imported: ${src}, skipping`)
      return Promise.resolve()
    }

    return new Promise((resolve, reject) => {
      const script = frameDocument.createElement("script")
      script.type = "module"
      script.textContent = `import ${module} from "${src}"`
      head.append(script)

      script.onload = () => {
        this.loadedResources.add(key)
        console.debug(`[Panda CMS] Module script loaded: ${src}`)
        resolve(script)
      }
      script.onerror = () => reject(new Error(`[Panda CMS] Module script load error for ${src}`))
    })
  }

  static loadStylesheet(frameDocument, head, href) {
    if (this.loadedResources.has(`stylesheet:${href}`)) {
      console.debug(`[Panda CMS] Stylesheet already loaded: ${href}, skipping`)
      return Promise.resolve()
    }

    return new Promise((resolve, reject) => {
      const link = frameDocument.createElement("link")
      link.rel = "stylesheet"
      link.href = href
      link.media = "none"
      head.append(link)

      link.onload = () => {
        if (link.media != "all") {
          link.media = "all"
        }
        this.loadedResources.add(`stylesheet:${href}`)
        console.debug(`[Panda CMS] Stylesheet loaded: ${href}`)
        resolve(link)
      }
      link.onerror = () => reject(new Error(`[Panda CMS] Stylesheet load error for ${href}`))
    })
  }

  /**
   * Simple string hashing function for tracking embedded CSS
   */
  static hashString(str) {
    let hash = 0
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i)
      hash = ((hash << 5) - hash) + char
      hash = hash & hash // Convert to 32bit integer
    }
    return hash.toString(36)
  }

  /**
   * Load a script into the document
   * @param {Document} doc - The document to load the script into
   * @param {HTMLElement} target - The element to append the script to
   * @param {string} url - The URL of the script to load
   * @returns {Promise<void>}
   */
  static async loadScript(doc, target, url) {
    return new ResourceLoader().loadScript(doc, target, url)
  }

  /**
   * Embed CSS into the document
   * @param {Document} doc - The document to embed the CSS into
   * @param {HTMLElement} target - The element to append the style to
   * @param {string} css - The CSS to embed
   * @returns {Promise<void>}
   */
  static async embedCSS(doc, target, css) {
    return new ResourceLoader().embedCSS(doc, target, css)
  }

  /**
   * Instance method to load a script
   */
  async loadScript(doc, target, url) {
    try {
      // Check if script is already loaded
      const existingScript = doc.querySelector(`script[src="${url}"]`)
      if (existingScript) {
        console.debug(`[Panda CMS] Script already loaded: ${url}, skipping`)
        return
      }

      // Create and configure script element
      const script = doc.createElement("script")
      script.type = "text/javascript"
      script.src = url
      script.async = true

      // Create a promise to track loading
      const loadPromise = new Promise((resolve, reject) => {
        script.onload = () => {
          console.debug(`[Panda CMS] Script loaded: ${url}`)
          resolve()
        }
        script.onerror = (error) => {
          console.error(`[Panda CMS] Script failed to load: ${url}`, error)
          reject(error)
        }
      })

      // Add script to document
      target.appendChild(script)

      // Wait for script to load
      await loadPromise
    } catch (error) {
      console.error(`[Panda CMS] Error loading script ${url}:`, error)
      throw error
    }
  }

  /**
   * Instance method to embed CSS
   */
  async embedCSS(doc, target, css) {
    try {
      // Check if styles are already embedded
      const existingStyle = doc.querySelector('style[data-panda-cms-styles]')
      if (existingStyle) {
        console.debug(`[Panda CMS] CSS already embedded, skipping`)
        return
      }

      // Create and configure style element
      const style = doc.createElement('style')
      style.setAttribute('data-panda-cms-styles', 'true')
      style.textContent = css

      // Add style to document
      target.appendChild(style)
      console.debug(`[Panda CMS] Embedded CSS styles`)
    } catch (error) {
      console.error('[Panda CMS] Error embedding CSS:', error)
      throw error
    }
  }
}
