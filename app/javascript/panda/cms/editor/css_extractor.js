export class CSSExtractor {
  /**
   * Extracts CSS rules from within a specific selector and transforms them for EditorJS
   * @param {string} css - The CSS content to parse
   * @returns {string} The extracted and transformed CSS rules
   */
  static extractStyles(css) {
    const rules = []
    let inComponents = false
    let inContentRule = false
    let braceCount = 0
    let currentRule = ''

    // Split CSS into lines and process each line
    const lines = css.split('\n')

    for (const line of lines) {
      const trimmedLine = line.trim()

      // Check if we're entering components layer
      if (trimmedLine === '@layer components {') {
        inComponents = true
        continue
      }

      // Only process lines within components layer
      if (!inComponents) continue

      // If we find the .content selector
      if (!inContentRule && trimmedLine.startsWith('.content')) {
        inContentRule = true
        braceCount++
        // Transform the selector for EditorJS
        currentRule = '.codex-editor__redactor .ce-block .ce-block__content'
        if (trimmedLine.includes('{')) {
          currentRule += ' {'
        }
        continue
      }

      // If we're inside a content rule
      if (inContentRule) {
        // Transform selectors for EditorJS
        let transformedLine = line
          .replace(/\.content\s+/g, '.codex-editor__redactor .ce-block .ce-block__content ')
          .replace(/\bh1\b(?![-_])/g, 'h1.ce-header')
          .replace(/\bh2\b(?![-_])/g, 'h2.ce-header')
          .replace(/\bh3\b(?![-_])/g, 'h3.ce-header')
          .replace(/\bul\b(?![-_])/g, 'ul.cdx-list')
          .replace(/\bol\b(?![-_])/g, 'ol.cdx-list')
          .replace(/\bli\b(?![-_])/g, 'li.cdx-list__item')
          .replace(/\bblockquote\b(?![-_])/g, '.cdx-quote')

        currentRule += '\n' + transformedLine

        // Count braces to handle nested rules
        braceCount += (trimmedLine.match(/{/g) || []).length
        braceCount -= (trimmedLine.match(/}/g) || []).length

        // If braces are balanced, we've found the end of the rule
        if (braceCount === 0) {
          rules.push(currentRule)
          inContentRule = false
          currentRule = ''
        }
      }
    }

    return rules.join('\n\n')
  }

  /**
   * Gets all styles from a stylesheet that apply to the editor
   * @param {string} css - The CSS content to parse
   * @returns {string} The extracted CSS rules
   */
  static getEditorStyles(css) {
    return this.extractStyles(css)
  }
}
