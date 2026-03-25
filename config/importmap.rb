# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

# Entry points (required by panda_core_javascript helper)
# These must use absolute paths to work with JavaScriptMiddleware
pin "panda/editor/application", to: "/panda/editor/application.js", preload: true
pin "panda/editor/controllers/index", to: "/panda/editor/controllers/index.js"

# Individual modules used by panda-cms controllers
pin "panda/editor/editor_js_config", to: "/panda/editor/editor_js_config.js"
pin "panda/editor/editor_js_initializer", to: "/panda/editor/editor_js_initializer.js"
pin "panda/editor/resource_loader", to: "/panda/editor/resource_loader.js"
pin "panda/editor/plain_text_editor", to: "/panda/editor/plain_text_editor.js"
pin "panda/editor/css_extractor", to: "/panda/editor/css_extractor.js"
pin "panda/editor/rich_text_editor", to: "/panda/editor/rich_text_editor.js"
pin "panda/editor/encoding", to: "/panda/editor/encoding.js"
pin "@editorjs/link-autocomplete", to: "/panda/editor/vendor/link-autocomplete.js"

# EditorJS ESM modules for importmap (used by rich_text_editor.js ES module imports)
pin "@editorjs/editorjs", to: "/panda/editor/vendor/@editorjs--editorjs@2.31.5.mjs" # @2.31.5
pin "@editorjs/paragraph", to: "/panda/editor/vendor/@editorjs--paragraph@2.11.7.mjs" # @2.11.7
pin "@editorjs/header", to: "/panda/editor/vendor/@editorjs--header@2.8.8.mjs" # @2.8.8
pin "@editorjs/nested-list", to: "/panda/editor/vendor/@editorjs--nested-list@1.4.3.mjs" # @1.4.3
pin "@editorjs/quote", to: "/panda/editor/vendor/@editorjs--quote@2.7.6.mjs" # @2.7.6
pin "@editorjs/table", to: "/panda/editor/vendor/@editorjs--table@2.4.5.mjs" # @2.4.5

# EditorJS UMD bundles (loaded via ResourceLoader.loadScript into editor iframe)
# These are NOT imported as ES modules — they are loaded as <script> tags into the
# editor iframe and expose globals (e.g. window.Paragraph, window.Header).
# See editor_js_config.js EDITOR_JS_RESOURCES for the actual paths.
# Versions: @editorjs/editorjs@2.31.5, @editorjs/paragraph@2.11.7,
#   @editorjs/header@2.8.8, @editorjs/nested-list@1.4.3, @editorjs/quote@2.7.6,
#   @editorjs/simple-image@1.6.0, @editorjs/table@2.4.5, @editorjs/embed@2.8.0,
#   @editorjs/link@2.6.2, @editorjs/attaches@1.3.2, @editorjs/image@2.10.3,
#   editorjs-undo@2.0.28
