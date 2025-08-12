// Panda Editor Application JavaScript
// This file serves as the entry point for all EditorJS functionality

import { EditorJSInitializer } from "./editor_js_initializer"
import { EditorJSConfig } from "./editor_js_config"
import { RichTextEditor } from "./rich_text_editor"

// Export for global access
window.PandaEditor = {
  EditorJSInitializer,
  EditorJSConfig,
  RichTextEditor,
  VERSION: "0.1.0"
}

// Auto-initialize on DOMContentLoaded
document.addEventListener("DOMContentLoaded", () => {
  console.log("[Panda Editor] Loaded v" + window.PandaEditor.VERSION)
  
  // Auto-initialize any editors on the page
  const editors = document.querySelectorAll("[data-panda-editor]")
  editors.forEach(element => {
    new EditorJSInitializer(element)
  })
})