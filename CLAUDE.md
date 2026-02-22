# CLAUDE.md

This file provides guidance to Claude Code when working with panda-editor.

**Parent:** See `~/Projects/panda/CLAUDE.md` for monorepo-wide rules (CSS compilation, JS architecture, ViewComponent requirements).

## Project Overview

Panda Editor is an EditorJS integration gem for Rails applications. Extracted from Panda CMS, it provides a modular, extensible rich text editor.

**Key features:**
- EditorJS block types and rendering
- Markdown-to-EditorJS conversion (via Redcarpet)
- HTML-to-EditorJS conversion (via Nokogiri)
- Footnote system with automatic numbering and deduplication
- Configurable via `dry-configurable`

## Dependencies

- Depends on **panda-core** (must load before panda-editor for ModuleRegistry)
- Uses Redcarpet for Markdown processing
- Uses Nokogiri for HTML parsing
- Uses Sanitize for content sanitization

## Development

### Testing
```bash
bundle exec rspec                    # Run all tests
bundle exec rspec spec/lib/          # Library tests
```

### Key Architecture
- **Block types**: `lib/panda/editor/blocks/` — each EditorJS block type
- **Renderer**: `lib/panda/editor/renderer.rb` — converts EditorJS JSON to HTML
- **Converters**: HTML-to-EditorJS and Markdown-to-EditorJS pipelines
- **JavaScript**: Stimulus controllers in `app/javascript/panda/editor/` served via importmap (no compilation)
- **Configuration**: `lib/panda/editor.rb` with `dry-configurable`

### Footnote System
The footnote system provides:
- Inline markers with automatic sequential numbering
- Collapsible sources section
- Source deduplication across the page
- Auto-linking of URLs in citation text
- See `docs/FOOTNOTES.md` for technical details
