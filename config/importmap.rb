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

# EditorJS Core and plugins (from esm.sh - better ES module handling than jsdelivr)
pin '@editorjs/editorjs', to: 'https://esm.sh/@editorjs/editorjs@2.28.2'
pin '@editorjs/paragraph', to: 'https://esm.sh/@editorjs/paragraph@2.11.3'
pin '@editorjs/header', to: 'https://esm.sh/@editorjs/header@2.8.1'
pin '@editorjs/nested-list', to: 'https://esm.sh/@editorjs/nested-list@1.4.2'
pin '@editorjs/quote', to: 'https://esm.sh/@editorjs/quote@2.6.0'
pin '@editorjs/simple-image', to: 'https://esm.sh/@editorjs/simple-image@1.6.0'
pin '@editorjs/table', to: 'https://esm.sh/@editorjs/table@2.3.0'
pin '@editorjs/embed', to: 'https://esm.sh/@editorjs/embed@2.7.0'
