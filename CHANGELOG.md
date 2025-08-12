# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.2.0]: https://github.com/tastybamboo/panda-editor/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/tastybamboo/panda-editor/releases/tag/v0.1.0