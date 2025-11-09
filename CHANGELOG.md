# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2025-11-09

### Added

- HTML to EditorJS converter for importing existing HTML content
  - Supports headers (h1-h6), paragraphs, lists (ordered/unordered), quotes, code blocks, tables, and delimiters
  - Preserves inline formatting (bold, italic, links, etc.) as HTML
  - Handles edge cases: empty content, malformed HTML, special characters, whitespace
  - Comprehensive test coverage (22 examples)
  - Available as `Panda::Editor::HtmlToEditorJsConverter.convert(html)`
- Markdown to EditorJS converter for importing Markdown content
  - Uses Redcarpet to parse markdown to HTML, then converts to EditorJS
  - Supports all standard markdown features: headers, paragraphs, lists, code blocks, tables, blockquotes
  - Includes advanced features: superscript, footnotes, strikethrough, autolinks
  - Security-hardened with noopener/noreferrer on links
  - Comprehensive test coverage (26 examples)
  - Available as `Panda::Editor::MarkdownToEditorJsConverter.convert(markdown)`
- Added nokogiri as explicit dependency (required for HTML parsing)

## [0.5.0] - 2025-11-04

### Fixed
- Code quality improvements with Rubocop auto-corrections
  - Fixed 1263 style violations across the codebase
  - Converted double-quoted strings to single quotes where appropriate
  - Improved code consistency and readability
  - Corrected string literal usage throughout
  - Fixed extra spacing and formatting issues

### Changed
- All tests passing (53 examples, 0 failures)
- Improved code maintainability

## [0.4.0] - 2025-10-30

### Added
- Markdown support for rich text formatting in footnotes
  - **Bold**, *italic*, `code`, ~~strikethrough~~, and [link](url) support
  - Automatic URL linking in markdown content
  - Security-hardened Redcarpet configuration (no images, safe links only)
  - Works alongside existing autolink_urls option
  - Comprehensive test coverage for markdown features
  - Updated documentation with markdown examples

## [0.3.0] - 2025-10-30

### Added
- Footnote support for academic citations and references
  - Ruby backend renderer for footnote processing
  - EditorJS inline tool for footnote insertion
  - Automatic footnote numbering and deduplication
  - Collapsible sources section in rendered output
  - Comprehensive footnote documentation

### Fixed
- Disabled caching for blocks containing footnotes to ensure accurate rendering
- Updated test expectations to match footnote behavior

### Changed
- Applied standardrb code style fixes across codebase

## [0.2.0] - 2025-08-12

### Added
- Full CI/CD pipeline with GitHub Actions
  - Automated testing across Ruby 3.2, 3.3 and Rails 7.1, 7.2, 8.0
  - StandardRB linting integration
  - YAML validation for workflow files
  - Security auditing with bundle-audit
  - Code coverage reporting with Codecov
- Automatic gem release workflow
  - Triggers on version changes after CI passes
  - Publishes to RubyGems automatically
  - Creates GitHub releases with changelogs
- Comprehensive test suite setup
  - RSpec configuration for Rails engine testing
  - Test helpers for HTML normalization
  - Support for EditorJS block testing
  - Rails view helpers integration in tests
- Development dependencies
  - Added rspec-rails for testing
  - Added standard gem for code linting
  - Added bundle-audit for security scanning
  - Added erb_lint for template linting

### Fixed
- Test infrastructure issues
  - Fixed Rails initialization for engine specs without dummy app
  - Improved HTML whitespace normalization in tests
  - Added missing ActionView helpers to test environment
- CI/CD pipeline issues
  - Fixed StandardRB version conflicts
  - Resolved YAML validation errors in workflows
  - Fixed missing test dependencies
  - Corrected workflow trigger dependencies

### Changed
- Improved test helper methods for better HTML comparison
- Simplified Rails test setup without requiring Sprockets
- Updated CI matrix to include Rails 8.0 support

## [0.1.0] - 2025-08-12

### Initial Release
- Extracted EditorJS functionality from Panda CMS into standalone gem
- Core editor blocks support:
  - Paragraph
  - Header
  - List (ordered and unordered)
  - Quote
  - Table
  - Image
  - Alert
  - Embed
- EditorJS renderer for converting block data to HTML
- Rails engine integration
- Importmap configuration for EditorJS assets
- Configurable custom block renderers
- HTML sanitization for security
- Asset pipeline integration

[0.3.0]: https://github.com/tastybamboo/panda-editor/compare/v0.2.1...v0.3.0
[0.2.0]: https://github.com/tastybamboo/panda-editor/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/tastybamboo/panda-editor/releases/tag/v0.1.0