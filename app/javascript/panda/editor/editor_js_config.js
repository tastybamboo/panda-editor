// Maps tool names to their vendored resource URLs.
// EditorJS core and undo are always loaded.
// Tools not in this map (e.g., footnote, pdf) are local — loaded via application.js.
const TOOL_RESOURCE_MAP = {
  paragraph: "/panda/editor/vendor/@editorjs--paragraph@2.11.7.js",
  header: "/panda/editor/vendor/@editorjs--header@2.8.8.js",
  list: "/panda/editor/vendor/@editorjs--nested-list@1.4.3.js",
  quote: "/panda/editor/vendor/@editorjs--quote@2.7.6.js",
  image: "/panda/editor/vendor/@editorjs--image@2.10.3.js",
  table: "/panda/editor/vendor/@editorjs--table@2.4.5.js",
  embed: "/panda/editor/vendor/@editorjs--embed@2.8.0.js",
  linkTool: "/panda/editor/vendor/@editorjs--link@2.6.2.js",
  attaches: "/panda/editor/vendor/@editorjs--attaches@1.3.2.js",
  link: "/panda/editor/vendor/link-autocomplete.js"
}

const ALWAYS_LOAD = [
  "/panda/editor/vendor/@editorjs--editorjs@2.31.5.js",
  "/panda/editor/vendor/editorjs-undo@2.0.28.js"
]

/**
 * Returns the list of CDN resources to load, filtered by enabled tools.
 * @param {Object|null} toolsConfig - The tools config from PANDA_EDITOR_TOOLS_CONFIG (null = load all)
 * @returns {string[]} Array of resource URLs to load
 */
export function getEditorResources(toolsConfig) {
  const resources = [...ALWAYS_LOAD]

  for (const [toolName, url] of Object.entries(TOOL_RESOURCE_MAP)) {
    // If no config provided, load all tools (backwards compatible)
    if (!toolsConfig || toolsConfig[toolName] !== undefined) {
      resources.push(url)
    }
  }

  // Allow applications to add their own resources
  if (window.PANDA_CMS_EDITOR_JS_RESOURCES) {
    resources.push(...window.PANDA_CMS_EDITOR_JS_RESOURCES)
  }

  return resources
}

// Default: load all resources (backwards compatible for callers that use EDITOR_JS_RESOURCES directly)
export const EDITOR_JS_RESOURCES = getEditorResources(null)

export const EDITOR_JS_CSS = `
  .codex-editor {
    position: relative;
    border-radius: 1rem;
    overflow: hidden;
  }
  .codex-editor::before {
    content: '';
    position: absolute;
    left: 0;
    top: 0;
    bottom: 0;
    width: 65px;
    margin-right: 5px;
    background-color: #f9fafb;
    border-right: 2px dashed #e5e7eb;
    z-index: 0;
  }
  .ce-block {
    padding-left: 70px;
    position: relative;
    min-height: 40px;
    margin: 0;
    padding-bottom: 1em;
  }
  .ce-block__content {
    position: relative;
    max-width: none;
    margin: 0;
  }
  .ce-paragraph {
    padding: 0;
    line-height: 1.6;
    min-height: 1.6em;
    margin: 0;
  }
  /* Override inherited heading styles */
  .ce-header h1,
  .ce-header h2,
  .ce-header h3,
  .ce-header h4,
  .ce-header h5,
  .ce-header h6 {
    margin: 0;
    padding: 0;
    line-height: 1.6;
    font-weight: 600;
  }
  .ce-header h1 { font-size: 2em; }
  .ce-header h2 { font-size: 1.5em; }
  .ce-header h3 { font-size: 1.17em; }
  .ce-header h4 { font-size: 1em; }
  .ce-header h5 { font-size: 0.83em; }
  .ce-header h6 { font-size: 0.67em; }

  .codex-editor__redactor {
    padding-bottom: 10px !important;
    min-height: 50px !important;
  }
  /* Add more padding for empty or short editors to provide clickable space */
  .codex-editor__redactor:has(.ce-block:only-child) {
    padding-bottom: 50px !important;
    min-height: 100px !important;
  }
  /* Base toolbar styles */
  .ce-toolbar {
    left: 0 !important;
    right: auto !important;
    background: none !important;
    position: absolute !important;
    width: 65px !important;
    height: 40px !important;
    display: flex !important;
    align-items: center !important;
    justify-content: flex-start !important;
    padding: 0 !important;
    margin-left: -70px !important;
    margin-top: -5px !important;
    opacity: 1 !important;
    visibility: visible !important;
    pointer-events: all !important;
    z-index: 2 !important;
  }
  /* Ensure toolbar is visible for all blocks */
  .ce-block .ce-toolbar {
    display: flex !important;
    opacity: 1 !important;
    visibility: visible !important;
  }
  .ce-toolbar__content {
    max-width: none;
    left: 70px !important;
    display: flex !important;
    position: relative !important;
  }
  .ce-toolbar__actions {
    position: relative !important;
    left: 5px !important;
    opacity: 1 !important;
    visibility: visible !important;
    background: transparent !important;
    z-index: 2;
    display: flex !important;
    align-items: center !important;
    gap: 5px !important;
    height: 40px !important;
    padding: 0 !important;
  }
  .ce-toolbar__plus {
    position: relative !important;
    left: 0px !important;
    opacity: 1 !important;
    visibility: visible !important;
    background: transparent !important;
    border: none !important;
    z-index: 2;
    display: block !important;
  }
  .ce-toolbar__settings-btn {
    position: relative !important;
    left: -10px !important;
    opacity: 1 !important;
    visibility: visible !important;
    background: transparent !important;
    border: none !important;
    z-index: 2;
    display: block !important;
  }
  /* Style the search input */
  .ce-popover__search {
    padding-left: 3px !important;
  }
  .ce-popover__search input {
    outline: none !important;
    box-shadow: none !important;
    border: none !important;
  }
  .ce-popover__search input::placeholder {
    content: 'Search';
  }
  /* Ensure popups still work */
  .ce-popover {
    z-index: 4;
  }
  .ce-inline-toolbar {
    z-index: 3;
  }
  /* Override any hiding behavior */
  .ce-toolbar--closed,
  .ce-toolbar--opened,
  .ce-toolbar--showed {
    display: flex !important;
    opacity: 1 !important;
    visibility: visible !important;
  }
  /* Force toolbar to show on every block */
  .ce-block:not(:focus):not(:hover) .ce-toolbar,
  .ce-block--selected .ce-toolbar,
  .ce-block--focused .ce-toolbar,
  .ce-block--hover .ce-toolbar {
    opacity: 1 !important;
    visibility: visible !important;
    display: flex !important;
  }

  /* Ensure last block has bottom spacing */
  .ce-block:last-child {
    padding-bottom: 1em;
  }

  /* Reset all block type margins */
  .ce-header,
  .ce-paragraph,
  .ce-quote,
  .ce-list {
    margin: 0 !important;
    padding: 0 !important;
  }

  /* Footnote marker styles */
  .footnote-marker {
    display: inline-block;
    color: #3b82f6;
    font-size: 0.75em;
    font-weight: 600;
    vertical-align: super;
    cursor: pointer;
    padding: 0 2px;
    user-select: none;
    margin-left: 1px;
  }

  .footnote-marker:hover {
    color: #2563eb;
    text-decoration: underline;
  }

  /* Inline toolbar button for footnote */
  .ce-inline-tool--footnote svg {
    width: 17px;
    height: 17px;
  }
`

/**
 * Deep-merge source into target (mutates target).
 * Arrays are replaced, not concatenated.
 */
function deepMerge(target, source) {
  for (const key of Object.keys(source)) {
    if (
      source[key] && typeof source[key] === 'object' && !Array.isArray(source[key]) &&
      target[key] && typeof target[key] === 'object' && !Array.isArray(target[key])
    ) {
      deepMerge(target[key], source[key])
    } else {
      target[key] = source[key]
    }
  }
  return target
}

/**
 * Builds the full tool definitions object for a given window context.
 * This contains ALL known tools — filtering happens afterwards.
 */
function buildAllToolDefinitions(win) {
  const csrfToken = win.PANDA_CMS_CSRF_TOKEN || win.document?.querySelector('meta[name="csrf-token"]')?.content

  return {
    paragraph: {
      class: win.ParagraphWithFootnotes || win.Paragraph,
      inlineToolbar: true,
      config: {
        placeholder: 'Start writing or press Tab to add content...'
      }
    },
    header: {
      class: win.Header,
      inlineToolbar: true,
      config: {
        placeholder: 'Enter a header',
        levels: [1, 2, 3, 4, 5, 6],
        defaultLevel: 2
      }
    },
    list: {
      class: win.NestedList,
      inlineToolbar: true,
      config: {
        defaultStyle: 'unordered',
        enableLineBreaks: true
      }
    },
    quote: {
      class: win.Quote,
      inlineToolbar: true,
      config: {
        quotePlaceholder: 'Enter a quote',
        captionPlaceholder: 'Quote\'s author'
      }
    },
    image: {
      class: win.ImageTool,
      inlineToolbar: true,
      config: {
        endpoints: {
          byFile: win.PANDA_CMS_EDITOR_JS_ENDPOINTS?.fileUpload
        },
        field: 'image',
        types: 'image/*',
        additionalRequestHeaders: {
          'X-CSRF-Token': csrfToken
        }
      }
    },
    table: {
      class: win.Table,
      inlineToolbar: true,
      config: {
        rows: 2,
        cols: 2
      }
    },
    embed: {
      class: win.Embed,
      inlineToolbar: true,
      config: {
        services: {
          youtube: true,
          vimeo: true
        }
      }
    },
    linkTool: {
      class: win.LinkTool,
      config: {
        endpoint: win.PANDA_CMS_EDITOR_JS_ENDPOINTS?.linkMetadata,
        headers: {
          'X-CSRF-Token': csrfToken
        }
      }
    },
    attaches: {
      class: win.AttachesTool,
      config: {
        endpoint: win.PANDA_CMS_EDITOR_JS_ENDPOINTS?.fileUpload,
        field: 'file',
        buttonText: 'Select file to upload',
        additionalRequestHeaders: {
          'X-CSRF-Token': csrfToken
        }
      }
    },
    footnote: {
      class: win.FootnoteTool
    },
    link: {
      class: win.LinkAutocomplete,
      config: {
        endpoint: win.PANDA_CMS_EDITOR_JS_ENDPOINTS?.editorSearch,
        queryParam: 'search'
      }
    },
    pdf: {
      class: win.PdfTool,
      config: {
        endpoint: win.PANDA_CMS_EDITOR_JS_ENDPOINTS?.fileUpload,
        field: 'file',
        csrfToken: csrfToken
      }
    }
  }
}

/**
 * Filters and configures tools based on the Ruby-provided tools config.
 * @param {Object} allTools - All tool definitions from buildAllToolDefinitions
 * @param {Object|null} toolsConfig - The config from PANDA_EDITOR_TOOLS_CONFIG (null = keep all)
 * @returns {Object} Filtered and configured tools
 */
function applyToolsConfig(allTools, toolsConfig) {
  if (!toolsConfig) return allTools

  const filtered = {}
  for (const [name, definition] of Object.entries(allTools)) {
    if (toolsConfig[name] !== undefined) {
      filtered[name] = definition
      // Merge any option overrides from the Ruby config into the tool's config
      const overrides = toolsConfig[name]
      if (overrides && typeof overrides === 'object' && Object.keys(overrides).length > 0 && definition.config) {
        deepMerge(definition.config, overrides)
      }
    }
  }
  return filtered
}

export const getEditorConfig = (elementId, previousData, doc = document) => {
  // Validate holder element exists
  const holder = doc.getElementById(elementId)
  if (!holder) {
    throw new Error(`Editor holder element ${elementId} not found`)
  }

  // Get the correct window context
  const win = doc.defaultView || window

  // Ensure we have a clean holder element
  holder.innerHTML = ""

  // Build all tool definitions, then filter by config
  const allTools = buildAllToolDefinitions(win)
  const toolsConfig = win.PANDA_EDITOR_TOOLS_CONFIG || null
  let tools = applyToolsConfig(allTools, toolsConfig)

  // Remove any tools whose class didn't load (CDN failure, etc.)
  tools = Object.fromEntries(
    Object.entries(tools)
      .filter(([_, value]) => value?.class !== undefined)
  )

  // Allow applications to add/override tools via window global
  if (win.PANDA_CMS_EDITOR_JS_CONFIG) {
    console.debug("[Panda CMS] Found custom EditorJS config:", Object.keys(win.PANDA_CMS_EDITOR_JS_CONFIG))
    Object.assign(tools, win.PANDA_CMS_EDITOR_JS_CONFIG)
  }

  const config = {
    holder: elementId,
    data: previousData || {},
    placeholder: 'Click the + button to add content...',
    inlineToolbar: true,
    onChange: () => {
      if (holder && holder.querySelector('.codex-editor')) {
        const event = new Event('editor:change', { bubbles: true })
        holder.dispatchEvent(event)
      }
    },
    i18n: {
      toolbar: {
        filter: {
          placeholder: 'Search'
        }
      }
    },
    tools
  }

  // Allow applications to customize the full config through JavaScript
  if (typeof win.customizeEditorJS === 'function') {
    win.customizeEditorJS(config)
  }

  return config
}

/**
 * patchLinkAutocomplete is no longer needed — the vendored link-autocomplete.js
 * has been modified directly to accept relative URLs and anchor links.
 * Kept as a no-op for backwards compatibility with callers.
 */
export function patchLinkAutocomplete(_win) {}

export function initializeEditorUndo(editor, win) {
  const w = win || window
  if (w.Undo) {
    try {
      new w.Undo({ editor })
      console.debug('[Panda CMS] EditorJS Undo initialized')
    } catch (e) {
      console.warn('[Panda CMS] Failed to initialize undo:', e)
    }
  }
}
