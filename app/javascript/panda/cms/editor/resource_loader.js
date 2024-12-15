export class ResourceLoader {
  /**
   * Embeds CSS styles into the document head.
   *
   * @param {Document} frameDocument - The document object to create elements in
   * @param {HTMLElement} head - The head element to append styles to
   * @param {string} css - The CSS styles to embed
   * @returns {Promise} A promise that resolves when the styles are embedded
   */
  static embedCSS(frameDocument, head, css) {
    return new Promise((resolve) => {
      const style = frameDocument.createElement("style")
      style.textContent = css
      head.append(style)
      resolve(style)
      console.debug("[Panda CMS] Embedded CSS styles")
    })
  }

  /**
   * Embeds a script element into the document head.
   *
   * @param {Document} frameDocument - The document object to create elements in
   * @param {HTMLElement} head - The head element to append the script to
   * @param {string} code - The JavaScript code to embed
   * @returns {Promise} A promise that resolves when the script is embedded
   */
  static embedScript(frameDocument, head, code) {
    return new Promise((resolve) => {
      const script = frameDocument.createElement("script")
      script.textContent = code
      head.append(script)
      resolve(script)
      console.debug("[Panda CMS] Embedded script")
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
    return new Promise((resolve, reject) => {
      const script = frameDocument.createElement("script")
      script.src = src
      resolve(script)

      script.onerror = () => reject(new Error(`[Panda CMS] Script load error for ${src}`))
      head.append(script)
    })
  }

  static importScript(frameDocument, head, module, src) {
    return new Promise((resolve, reject) => {
      const script = frameDocument.createElement("script")
      script.type = "module"
      script.textContent = `import ${module} from "${src}"`
      head.append(script)

      script.onload = () => {
        console.debug(`[Panda CMS] Module script loaded: ${src}`)
        resolve(script)
      }
      script.onerror = () => reject(new Error(`[Panda CMS] Module script load error for ${src}`))
    })
  }

  static embedScript(description, frameDocument, head, code) {
    return new Promise((resolve) => {
      const script = frameDocument.createElement("script")
      script.textContent = code
      head.append(script)
      resolve(script)
      console.debug(`[Panda CMS] Embedded script loaded (${description})`)
    })
  }

  static loadStylesheet(frameDocument, head, href) {
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
        console.debug(`[Panda CMS] Stylesheet loaded: ${href}`)
        resolve(link)
      }
      link.onerror = () => reject(new Error(`[Panda CMS] Stylesheet load error for ${href}`))
    })
  }

  static embedCSS(frameDocument, head, css) {
    return new Promise((resolve) => {
      const style = frameDocument.createElement("style")
      style.textContent = css
      head.append(style)
      console.debug(`[Panda CMS] Embedded CSS loaded`)
      resolve(style)
    })
  }
}
