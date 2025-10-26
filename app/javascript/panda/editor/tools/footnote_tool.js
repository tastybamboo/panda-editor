/**
 * FootnoteTool - EditorJS Inline Tool for adding footnotes
 *
 * This tool allows users to add footnotes to text by:
 * 1. Selecting text and clicking the footnote button
 * 2. Entering the citation content in a modal
 * 3. Automatically generating a unique ID
 * 4. Storing the footnote data in the paragraph block
 * 5. Displaying a visual marker (superscript number) in the editor
 */

export default class FootnoteTool {
  /**
   * EditorJS inline tool interface
   */
  static get isInline() {
    return true;
  }

  static get title() {
    return 'Footnote';
  }

  /**
   * Sanitize config - allow sup tags with our footnote classes
   */
  static get sanitize() {
    return {
      sup: {
        class: 'footnote-marker'
      }
    };
  }

  /**
   * Constructor
   * @param {object} params - Tool parameters from EditorJS
   */
  constructor({ api }) {
    this.api = api;
    this.button = null;
    this.state = false;

    // Store reference to active footnotes for this paragraph
    this.footnotes = [];

    // CSS classes
    this.CSS = {
      button: 'ce-inline-tool',
      buttonActive: 'ce-inline-tool--active',
      buttonModifier: 'ce-inline-tool--footnote'
    };

    // SVG icon for superscript/footnote
    this.iconSVG = `<svg xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <text x="2" y="18" font-size="14" font-weight="bold">fn</text>
      <text x="12" y="8" font-size="8" font-weight="bold">1</text>
    </svg>`;
  }

  /**
   * Create button for inline toolbar
   */
  render() {
    this.button = document.createElement('button');
    this.button.type = 'button';
    this.button.classList.add(this.CSS.button, this.CSS.buttonModifier);
    this.button.innerHTML = this.iconSVG;

    return this.button;
  }

  /**
   * Handle click on the footnote button
   * @param {Range} range - Selected text range
   */
  surround(range) {
    if (this.state) {
      // Remove footnote if already exists
      this.unwrap(range);
      return;
    }

    // Get the selected text position within the paragraph
    const position = this.getCaretPosition(range);

    // Show modal to collect footnote content
    this.showFootnoteModal((content) => {
      if (!content || content.trim() === '') {
        return;
      }

      // Generate unique ID
      const footnoteId = this.generateFootnoteId();

      // Wrap selection with marker (stores content in data attribute)
      this.wrap(range, footnoteId, content.trim());
    });
  }

  /**
   * Wrap selected text with footnote marker
   * @param {Range} range - Selected text range
   * @param {string} footnoteId - Unique footnote identifier
   * @param {string} content - Footnote content/citation
   */
  wrap(range, footnoteId, content) {
    const marker = document.createElement('sup');
    marker.classList.add('footnote-marker');
    marker.dataset.footnoteId = footnoteId;
    marker.dataset.footnoteContent = content; // Store content in data attribute
    marker.contentEditable = false;

    // Insert marker at the end of selection
    range.collapse(false); // Collapse to end
    range.insertNode(marker);

    // Move cursor after marker
    range.setStartAfter(marker);
    range.collapse(true);

    // Update selection
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);

    // Renumber all footnotes in the document
    setTimeout(() => this.renumberAllFootnotes(), 0);
  }

  /**
   * Remove footnote marker
   * @param {Range} range - Selected text range
   */
  unwrap(range) {
    const marker = this.findMarkerInRange(range);
    if (marker) {
      marker.remove();

      // Renumber remaining footnotes
      setTimeout(() => this.renumberAllFootnotes(), 0);
    }
  }

  /**
   * Check if current selection has a footnote
   * @param {Range} range - Current selection range
   */
  checkState(selection) {
    if (!selection || !selection.anchorNode) {
      this.state = false;
      return false;
    }

    const marker = this.findMarkerInSelection(selection);
    this.state = !!marker;

    return this.state;
  }

  /**
   * Find footnote marker in current selection
   * @param {Selection} selection - Current selection
   * @returns {Element|null} Footnote marker element if found
   */
  findMarkerInSelection(selection) {
    if (!selection.anchorNode) return null;

    let node = selection.anchorNode;

    // Traverse up to find marker
    while (node && node !== this.api.blocks.getCurrentBlockIndex()) {
      if (node.nodeType === Node.ELEMENT_NODE &&
          node.tagName === 'SUP' &&
          node.classList.contains('footnote-marker')) {
        return node;
      }
      node = node.parentNode;
    }

    return null;
  }

  /**
   * Find footnote marker in a range
   * @param {Range} range - Selection range
   * @returns {Element|null} Footnote marker element if found
   */
  findMarkerInRange(range) {
    const container = range.commonAncestorContainer;

    if (container.nodeType === Node.ELEMENT_NODE &&
        container.classList.contains('footnote-marker')) {
      return container;
    }

    const markers = container.querySelectorAll?.('.footnote-marker');
    return markers?.[0] || null;
  }

  /**
   * Get caret position within the paragraph text
   * @param {Range} range - Current selection range
   * @returns {number} Character position
   */
  getCaretPosition(range) {
    const block = this.api.blocks.getBlockByIndex(this.api.blocks.getCurrentBlockIndex());
    const blockElement = block.holder;
    const contentElement = blockElement.querySelector('.ce-paragraph');

    if (!contentElement) return 0;

    // Create a range from start of content to current position
    const preCaretRange = range.cloneRange();
    preCaretRange.selectNodeContents(contentElement);
    preCaretRange.setEnd(range.endContainer, range.endOffset);

    // Get text content length (position)
    return preCaretRange.toString().length;
  }

  /**
   * Generate a unique footnote ID
   * @returns {string} Unique identifier
   */
  generateFootnoteId() {
    return `fn-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Renumber all footnotes in the entire document
   * Scans all blocks and updates footnote marker numbers sequentially
   */
  renumberAllFootnotes() {
    try {
      const blocksCount = this.api.blocks.getBlocksCount();
      let footnoteNumber = 0;

      // Scan through all blocks in order
      for (let i = 0; i < blocksCount; i++) {
        const block = this.api.blocks.getBlockByIndex(i);
        if (!block) continue;

        const blockElement = block.holder;
        const markers = blockElement.querySelectorAll('.footnote-marker');

        // Update each marker in this block
        markers.forEach(marker => {
          footnoteNumber++;
          marker.textContent = footnoteNumber.toString();
        });
      }

      console.debug('[Footnote Tool] Renumbered', footnoteNumber, 'footnotes');
    } catch (error) {
      console.error('[Footnote Tool] Error renumbering footnotes:', error);
    }
  }


  /**
   * Show modal dialog to collect footnote content
   * @param {Function} onSave - Callback when user saves
   */
  showFootnoteModal(onSave) {
    // Create modal overlay
    const overlay = document.createElement('div');
    overlay.className = 'footnote-modal-overlay';
    overlay.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 10000;
    `;

    // Create modal content
    const modal = document.createElement('div');
    modal.className = 'footnote-modal';
    modal.style.cssText = `
      background: white;
      border-radius: 8px;
      padding: 24px;
      max-width: 500px;
      width: 90%;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    `;

    modal.innerHTML = `
      <h3 style="margin: 0 0 16px 0; font-size: 18px; font-weight: 600;">Add Footnote</h3>
      <div style="margin-bottom: 16px;">
        <label style="display: block; margin-bottom: 8px; font-size: 14px; font-weight: 500;">
          Citation Content
        </label>
        <textarea
          class="footnote-content-input"
          placeholder="Enter citation or reference (e.g., Smith, J. et al. (2023). Study Title. Journal Name.)"
          style="
            width: 100%;
            min-height: 100px;
            padding: 8px 12px;
            border: 1px solid #d1d5db;
            border-radius: 4px;
            font-size: 14px;
            font-family: inherit;
            resize: vertical;
          "
        ></textarea>
        <p style="margin: 8px 0 0 0; font-size: 12px; color: #6b7280;">
          Tip: You can paste URLs directly - they'll be automatically converted to clickable links.
        </p>
      </div>
      <div style="display: flex; gap: 8px; justify-content: flex-end;">
        <button class="footnote-cancel-btn" style="
          padding: 8px 16px;
          border: 1px solid #d1d5db;
          border-radius: 4px;
          background: white;
          color: #374151;
          font-size: 14px;
          font-weight: 500;
          cursor: pointer;
        ">Cancel</button>
        <button class="footnote-save-btn" style="
          padding: 8px 16px;
          border: none;
          border-radius: 4px;
          background: #3b82f6;
          color: white;
          font-size: 14px;
          font-weight: 500;
          cursor: pointer;
        ">Add Footnote</button>
      </div>
    `;

    overlay.appendChild(modal);
    document.body.appendChild(overlay);

    // Get elements
    const textarea = modal.querySelector('.footnote-content-input');
    const saveBtn = modal.querySelector('.footnote-save-btn');
    const cancelBtn = modal.querySelector('.footnote-cancel-btn');

    // Focus textarea
    setTimeout(() => textarea.focus(), 0);

    // Handle save
    const handleSave = () => {
      const content = textarea.value;
      onSave(content);
      overlay.remove();
    };

    // Handle cancel
    const handleCancel = () => {
      overlay.remove();
    };

    // Event listeners
    saveBtn.addEventListener('click', handleSave);
    cancelBtn.addEventListener('click', handleCancel);
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        handleCancel();
      }
    });

    // Handle Enter key (with Shift for new line)
    textarea.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        handleSave();
      } else if (e.key === 'Escape') {
        e.preventDefault();
        handleCancel();
      }
    });
  }

  /**
   * Optional: Clear tool state
   */
  clear() {
    this.state = false;
  }
}
