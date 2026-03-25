// Panda Editor Application JavaScript
// This file serves as the entry point for all EditorJS functionality

import { EditorJSInitializer } from "./editor_js_initializer.js"
import { EDITOR_JS_RESOURCES, EDITOR_JS_CSS, getEditorConfig } from "./editor_js_config.js"
import RichTextEditor from "./rich_text_editor.js"
import FootnoteTool from "./tools/footnote_tool.js"
import ParagraphWithFootnotes from "./tools/paragraph_with_footnotes.js"
import PdfTool from "./tools/pdf_tool.js"

// Export for global access
window.PandaEditor = {
  EditorJSInitializer,
  EDITOR_JS_RESOURCES,
  EDITOR_JS_CSS,
  getEditorConfig,
  RichTextEditor,
  FootnoteTool,
  ParagraphWithFootnotes,
  PdfTool,
  VERSION: "0.1.0"
}

// Make tools available globally for EditorJS
window.FootnoteTool = FootnoteTool
window.ParagraphWithFootnotes = ParagraphWithFootnotes
window.PdfTool = PdfTool

// Auto-initialize on DOMContentLoaded
document.addEventListener("DOMContentLoaded", () => {
  console.log("[Panda Editor] Loaded v" + window.PandaEditor.VERSION)
  
  // Auto-initialize any editors on the page
  const editors = document.querySelectorAll("[data-panda-editor]")
  editors.forEach(element => {
    new EditorJSInitializer(element)
  })
})