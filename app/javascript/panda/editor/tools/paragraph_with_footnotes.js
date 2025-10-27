/**
 * ParagraphWithFootnotes - Custom Paragraph Block for EditorJS with Footnote Support
 *
 * This extends the default Paragraph tool to add support for storing and
 * managing footnote data alongside the text content.
 */

export default class ParagraphWithFootnotes {
  /**
   * EditorJS block tool interface
   */
  static get toolbox() {
    return {
      title: 'Paragraph',
      icon: '<svg width="17" height="15" viewBox="0 0 336 276" xmlns="http://www.w3.org/2000/svg"><path d="M291 150V79c0-19-15-34-34-34H79c-19 0-34 15-34 34v42l67-44 81 72 56-29 42 30zm0 52l-43-30-56 30-81-67-66 39v23c0 19 15 34 34 34h178c17 0 31-13 34-29zM79 0h178c44 0 79 35 79 79v118c0 44-35 79-79 79H79c-44 0-79-35-79-79V79C0 35 35 0 79 0z"/></svg>'
    };
  }

  static get contentless() {
    return false;
  }

  static get enableLineBreaks() {
    return true;
  }

  static get DEFAULT_PLACEHOLDER() {
    return 'Start writing or press Tab to add content...';
  }

  /**
   * Allow to press Enter inside the CodeTool textarea
   * @returns {boolean}
   * @public
   */
  static get enableLineBreaks() {
    return true;
  }

  /**
   * Constructor
   * @param {object} params - Tool parameters
   * @param {object} params.data - Previously saved data
   * @param {object} params.config - Tool config
   * @param {object} params.api - EditorJS API
   * @param {boolean} params.readOnly - Read-only mode
   */
  constructor({ data, config, api, readOnly }) {
    this.api = api;
    this.readOnly = readOnly;

    this._CSS = {
      block: this.api.styles.block,
      wrapper: 'ce-paragraph'
    };

    if (!this.readOnly) {
      this.onKeyUp = this.onKeyUp.bind(this);
    }

    this._placeholder = config.placeholder ? config.placeholder : ParagraphWithFootnotes.DEFAULT_PLACEHOLDER;
    this._data = {};
    this._element = null;
    this._preserveBlank = config.preserveBlank !== undefined ? config.preserveBlank : false;

    this.data = data;
  }

  /**
   * Create paragraph element
   * @returns {HTMLElement}
   */
  render() {
    const div = document.createElement('DIV');
    div.classList.add(this._CSS.wrapper, this._CSS.block);
    div.contentEditable = !this.readOnly;
    div.dataset.placeholder = this.api.i18n.t(this._placeholder);

    if (this._data.text) {
      div.innerHTML = this._data.text;
    }

    if (!this.readOnly) {
      div.addEventListener('keyup', this.onKeyUp);
    }

    this._element = div;

    return div;
  }

  /**
   * Handle keyup event
   * @param {KeyboardEvent} event
   */
  onKeyUp(event) {
    if (event.code !== 'Backspace' && event.code !== 'Delete') {
      return;
    }

    const { textContent } = this._element;

    if (textContent === '') {
      this._element.innerHTML = '';
    }
  }

  /**
   * Validate saved data
   * @param {object} savedData - Data to validate
   * @returns {boolean}
   */
  validate(savedData) {
    if (savedData.text?.trim() === '' && !this._preserveBlank) {
      return false;
    }

    return true;
  }

  /**
   * Save paragraph data
   * @param {HTMLElement} toolsContent - Paragraph element
   * @returns {object} Saved data
   */
  save(toolsContent) {
    // Clone the element to work with it without modifying the DOM
    const clone = toolsContent.cloneNode(true);

    // Extract footnotes before removing markers
    const footnotes = this.extractFootnotes(clone);

    // Remove all footnote markers from the clone to get clean text
    const markers = clone.querySelectorAll('.footnote-marker');
    markers.forEach(marker => marker.remove());

    const data = {
      text: clone.innerHTML
    };

    // Add footnotes array if any exist
    if (footnotes.length > 0) {
      data.footnotes = footnotes;
    }

    return data;
  }

  /**
   * Extract footnotes from the paragraph content
   * @param {HTMLElement} element - Paragraph element
   * @returns {Array} Array of footnote objects
   */
  extractFootnotes(element) {
    const footnotes = [];
    const markers = element.querySelectorAll('.footnote-marker');

    markers.forEach((marker) => {
      const footnoteId = marker.dataset.footnoteId;
      const footnoteContent = marker.dataset.footnoteContent;

      if (footnoteId && footnoteContent) {
        // Calculate position by getting all text before this marker
        const range = document.createRange();
        range.selectNodeContents(element);
        range.setEnd(marker, 0);
        const position = range.toString().length;

        footnotes.push({
          id: footnoteId,
          content: footnoteContent,
          position: position
        });
      }
    });

    return footnotes;
  }

  /**
   * Merge tool with similar block
   * @param {object} data - Saved data from other block
   */
  merge(data) {
    const newData = {
      text: this.data.text + data.text
    };

    this.data = newData;
  }

  /**
   * Get current data
   * @returns {object}
   */
  get data() {
    let text = this._element ? this._element.innerHTML : this._data.text || '';

    this._data.text = text;

    // Also update footnotes from current markers
    if (this._element) {
      const footnotes = this.extractFootnotes(this._element);
      if (footnotes.length > 0) {
        this._data.footnotes = footnotes;
      }
    }

    return this._data;
  }

  /**
   * Set data
   * @param {object} data - Data to set
   */
  set data(data) {
    this._data = data || {};

    if (this._element) {
      this._element.innerHTML = this._data.text || '';
    }
  }

  /**
   * Used by EditorJS paste handling
   * @param {string} content - Content to set
   */
  onPaste(event) {
    const data = {
      text: event.detail.data.innerHTML
    };

    this.data = data;
  }

  /**
   * Enable Conversion Toolbar
   * @returns {object}
   */
  static get conversionConfig() {
    return {
      export: 'text', // use 'text' property for other blocks
      import: 'text' // fill 'text' property from other block's export string
    };
  }

  /**
   * Sanitizer rules
   * @returns {object}
   */
  static get sanitize() {
    return {
      text: {
        br: true,
        sup: {
          class: 'footnote-marker',
          'data-footnote-id': true,
          'data-footnote-content': true
        }
      }
    };
  }

  /**
   * Returns true to notify core that read-only is supported
   * @returns {boolean}
   */
  static get isReadOnlySupported() {
    return true;
  }

  /**
   * Get current Tool`s data
   * @returns {object} Current data
   * @public
   */
  get currentBlock() {
    return this.api.blocks.getCurrentBlockIndex();
  }
}
