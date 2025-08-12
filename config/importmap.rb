# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin_all_from "app/javascript/panda/editor", under: "panda/editor"

# EditorJS Core and plugins (from CDN)
pin "@editorjs/editorjs", to: "https://cdn.jsdelivr.net/npm/@editorjs/editorjs@2.28.2/+esm"
pin "@editorjs/paragraph", to: "https://cdn.jsdelivr.net/npm/@editorjs/paragraph@2.11.3/+esm"
pin "@editorjs/header", to: "https://cdn.jsdelivr.net/npm/@editorjs/header@2.8.1/+esm"
pin "@editorjs/nested-list", to: "https://cdn.jsdelivr.net/npm/@editorjs/nested-list@1.4.2/+esm"
pin "@editorjs/quote", to: "https://cdn.jsdelivr.net/npm/@editorjs/quote@2.6.0/+esm"
pin "@editorjs/simple-image", to: "https://cdn.jsdelivr.net/npm/@editorjs/simple-image@1.6.0/+esm"
pin "@editorjs/table", to: "https://cdn.jsdelivr.net/npm/@editorjs/table@2.3.0/+esm"
pin "@editorjs/embed", to: "https://cdn.jsdelivr.net/npm/@editorjs/embed@2.7.0/+esm"
