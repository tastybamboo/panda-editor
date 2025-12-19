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

# EditorJS Core and plugins (from CDN)
pin '@editorjs/editorjs', to: 'https://cdn.jsdelivr.net/npm/@editorjs/editorjs@2.28.2/+esm'
pin '@editorjs/paragraph', to: 'https://cdn.jsdelivr.net/npm/@editorjs/paragraph@2.11.3/+esm'
pin '@editorjs/header', to: 'https://cdn.jsdelivr.net/npm/@editorjs/header@2.8.1/+esm'
pin '@editorjs/nested-list', to: 'https://cdn.jsdelivr.net/npm/@editorjs/nested-list@1.4.2/+esm'
pin '@editorjs/quote', to: 'https://cdn.jsdelivr.net/npm/@editorjs/quote@2.6.0/+esm'
pin '@editorjs/simple-image', to: 'https://cdn.jsdelivr.net/npm/@editorjs/simple-image@1.6.0/+esm'
pin '@editorjs/table', to: 'https://cdn.jsdelivr.net/npm/@editorjs/table@2.3.0/+esm'
pin '@editorjs/embed', to: 'https://cdn.jsdelivr.net/npm/@editorjs/embed@2.7.0/+esm'
