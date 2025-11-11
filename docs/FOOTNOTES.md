# Footnotes in Panda Editor

Panda Editor provides a powerful footnote system that allows you to add inline citations and references to your content. Footnotes are automatically collected, numbered, and rendered in a collapsible "Sources/References" section at the end of your document.

## Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [JSON Structure](#json-structure)
- [Field Reference](#field-reference)
- [Rendered Output](#rendered-output)
- [Frontend Integration](#frontend-integration)
- [Advanced Features](#advanced-features)
- [CSS Styling](#css-styling)
- [Examples](#examples)

## Overview

The footnote system consists of three main components:

1. **Paragraph Block**: Accepts footnote data within paragraph blocks and injects inline markers
2. **FootnoteRegistry**: Collects and numbers footnotes across the entire document
3. **Renderer**: Coordinates footnote processing and generates the sources section

### Key Features

- ✨ **Automatic numbering**: Sequential numbering across the entire document
- 🔄 **De-duplication**: Same source cited multiple times uses the same footnote number
- 📍 **Position-based injection**: Place footnote markers at any character position
- 🎨 **Collapsible UI**: Clean, accessible sources section
- 🔗 **Bidirectional links**: Navigate between citations and sources
- 💬 **Hover tooltips**: Preview footnote content without scrolling to sources

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    EditorJS JSON                        │
│  (Contains blocks with embedded footnote data)          │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────┐
│                     Renderer                            │
│  - Creates FootnoteRegistry                             │
│  - Passes registry to all blocks via options            │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────┐
│                  Paragraph Block                        │
│  - Processes footnotes array                            │
│  - Registers each footnote with registry                │
│  - Injects <sup> markers at specified positions         │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────┐
│                 FootnoteRegistry                        │
│  - Assigns sequential numbers                           │
│  - Tracks footnotes by ID for de-duplication            │
│  - Generates sources section HTML                       │
└─────────────────────────────────────────────────────────┘
```

### Processing Flow

1. **Initialization**: Renderer creates a `FootnoteRegistry` instance
2. **Block Rendering**: Each paragraph block processes its footnotes:
   - Sorts footnotes by position (descending) to avoid position shifts
   - Registers each footnote with the registry
   - Receives a footnote number back
   - Injects superscript marker at the specified position
3. **Sources Generation**: After all blocks are rendered, the renderer:
   - Checks if any footnotes were collected
   - Appends the sources section if footnotes exist

## JSON Structure

Add footnotes to any paragraph block in your EditorJS JSON:

```json
{
  "type": "paragraph",
  "data": {
    "text": "Climate change has accelerated significantly since 1980",
    "footnotes": [
      {
        "id": "fn-uuid-123",
        "content": "IPCC. (2023). Climate Change 2023: Synthesis Report.",
        "position": 55
      }
    ]
  }
}
```

### Multiple Footnotes

```json
{
  "type": "paragraph",
  "data": {
    "text": "Global temperature has risen 1.1°C since pre-industrial times",
    "footnotes": [
      {
        "id": "fn-uuid-456",
        "content": "NASA. (2023). Global Climate Change: Vital Signs.",
        "position": 35
      },
      {
        "id": "fn-uuid-789",
        "content": "NOAA. (2023). State of the Climate Report.",
        "position": 62
      }
    ]
  }
}
```

### Reusing Sources

To cite the same source multiple times, use the same `id`:

```json
{
  "blocks": [
    {
      "type": "paragraph",
      "data": {
        "text": "First mention of the study",
        "footnotes": [{
          "id": "fn-study-2023",
          "content": "Smith et al. (2023). Important Study.",
          "position": 26
        }]
      }
    },
    {
      "type": "paragraph",
      "data": {
        "text": "Second mention of the same study",
        "footnotes": [{
          "id": "fn-study-2023",
          "content": "Smith et al. (2023). Important Study.",
          "position": 33
        }]
      }
    }
  ]
}
```

Both paragraphs will reference the same footnote number, and the source will appear only once in the sources section.

## Field Reference

### `id` (required)

- **Type**: String
- **Purpose**: Unique identifier for the footnote
- **Best Practice**: Use UUIDs or descriptive IDs like `fn-study-name-year`
- **De-duplication**: Footnotes with the same `id` will share the same number

### `content` (required)

- **Type**: String
- **Purpose**: The citation or reference text
- **HTML Support**: Basic HTML tags are sanitized and allowed
- **Best Practice**: Use standard citation formats (APA, MLA, etc.)

### `position` (required)

- **Type**: Integer
- **Purpose**: Character position where the footnote marker should be inserted
- **Zero-indexed**: Position 0 is before the first character
- **Validation**: Must be between 0 and text length (inclusive)

## Rendered Output

### Inline Markers

Footnote markers include native browser tooltips and data attributes for custom tooltip implementations:

```html
<p>Climate change has accelerated significantly since 1980<sup id="fnref:1" class="footnote-ref" data-footnote-content="IPCC. (2023). Climate Change 2023: Synthesis Report." title="IPCC. (2023). Climate Change 2023: Synthesis Report."><a href="#fn:1" class="footnote">1</a></sup></p>
```

**Tooltip Attributes:**
- `class="footnote-ref"` - Identifies footnote markers for styling
- `data-footnote-content` - Contains processed footnote content (with markdown/HTML if enabled) for custom tooltips
- `title` - Contains plain text version for native browser tooltips on hover

### Sources Section

```html
<div class="mx-6 lg:mx-8 mt-4 mb-8">
  <div class="footnotes-section bg-gray-50 rounded-lg overflow-hidden">
    <button class="footnotes-header w-full px-4 py-3 flex items-center justify-between cursor-pointer hover:bg-gray-100 transition-colors"
            data-footnotes-target="toggle"
            data-action="click->footnotes#toggle">
      <h3 class="text-sm font-unbounded font-medium text-gray-900 m-0">Sources/References</h3>
      <svg class="footnotes-chevron w-5 h-5 text-gray-600"
           data-footnotes-target="chevron"
           fill="none"
           stroke="currentColor"
           viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
      </svg>
    </button>
    <div class="footnotes-content" data-footnotes-target="content">
      <ol class="footnotes text-sm text-gray-700 space-y-2 px-4 pb-3">
        <li id="fn:1">
          <p>
            IPCC. (2023). Climate Change 2023: Synthesis Report.
            <a href="#fnref:1" class="footnote-backref">↩</a>
          </p>
        </li>
      </ol>
    </div>
  </div>
</div>
```

## Frontend Integration

The sources section includes data attributes designed for use with JavaScript frameworks like Stimulus:

### Data Attributes

- `data-footnotes-target="toggle"` - The clickable header button
- `data-footnotes-target="content"` - The collapsible content section
- `data-footnotes-target="chevron"` - The chevron icon for rotation animation

### Example Stimulus Controller

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "content", "chevron"]

  connect() {
    // Start collapsed
    this.contentTarget.classList.add("hidden")
  }

  toggle(event) {
    event.preventDefault()

    const isHidden = this.contentTarget.classList.contains("hidden")

    if (isHidden) {
      this.contentTarget.classList.remove("hidden")
      this.chevronTarget.style.transform = "rotate(180deg)"
    } else {
      this.contentTarget.classList.add("hidden")
      this.chevronTarget.style.transform = "rotate(0deg)"
    }
  }
}
```

### Accessible Mode

The footnotes section is designed to be accessible:

- Semantic HTML (`<button>`, `<ol>`, proper heading levels)
- ARIA-ready structure (add `aria-expanded` as needed)
- Keyboard navigation (links and buttons are focusable)
- Clear visual hierarchy

## Advanced Features

### Position Calculation

When determining where to place a footnote marker, count characters from the beginning of the text:

```javascript
const text = "Hello world"
//            0123456789...

// To place marker after "Hello"
position = 5

// Result: "Hello<sup>1</sup> world"
```

### Handling HTML in Text

If your paragraph contains HTML tags, remember that `position` refers to the character position in the **rendered HTML string**:

```javascript
const text = "Text with <b>bold</b> formatting"
// Position 10 is after "Text with "
// Position 13 is inside the <b> tag (after "<b>")
```

Best practice: Calculate positions based on plain text, not HTML.

### Sorting and Insertion

The paragraph block sorts footnotes by position in **descending order** before insertion. This prevents position shifts:

```ruby
# Without sorting (wrong):
text = "Hello world"
insert at position 5: "Hello<sup>1</sup> world"  # Now position 11 shifted!
insert at position 11: Error - position too far

# With sorting (correct):
text = "Hello world"
insert at position 11: "Hello world<sup>2</sup>"
insert at position 5: "Hello<sup>1</sup> world<sup>2</sup>"
```

### Markdown Support

The footnote system supports markdown formatting, allowing you to use rich text formatting in your citations.

**Enable markdown:**

```ruby
renderer = Panda::Editor::Renderer.new(content, markdown: true)
output = renderer.render
```

**Supported markdown features:**

- **Bold text** (`**bold**` or `__bold__`)
- *Italic text* (`*italic*` or `_italic_`)
- `Inline code` (`` `code` ``)
- ~~Strikethrough~~ (`~~text~~`)
- [Links](url) (`[text](url)`)
- Automatic URL linking

**Example:**

```ruby
content = {
  "blocks" => [{
    "type" => "paragraph",
    "data" => {
      "text" => "Research findings",
      "footnotes" => [{
        "id" => "fn-1",
        "content" => "Smith, J. (2023). **Important study** on *ADHD treatment*. See https://example.com for details.",
        "position" => 17
      }]
    }
  }]
}

renderer = Panda::Editor::Renderer.new(content, markdown: true)
# Output will include: Smith, J. (2023). <strong>Important study</strong> on <em>ADHD treatment</em>. See <a href="https://example.com">https://example.com</a> for details.
```

**Important notes:**

- Markdown includes built-in URL autolinking, so you typically don't need `autolink_urls: true` when using markdown
- However, both options can be used together if needed - the custom autolink_urls will skip URLs that markdown already linked
- Markdown links are rendered with `target="_blank"` and `rel="noopener noreferrer"` for security
- Images are disabled in markdown footnotes for security
- HTML styles are stripped from markdown output

### Auto-linking URLs

The footnote system can automatically convert plain URLs in footnote content into clickable links when markdown is not enabled.

**Enable auto-linking:**

```ruby
renderer = Panda::Editor::Renderer.new(content, autolink_urls: true)
output = renderer.render
```

**How it works:**

Plain URLs in footnote content are detected and wrapped in `<a>` tags:

```ruby
# Input footnote content:
"Ward, J.H. & Curran, S. (2021). https://doi.org/10.1111/camh.12471"

# Rendered output:
"Ward, J.H. & Curran, S. (2021). <a href=\"https://doi.org/10.1111/camh.12471\" target=\"_blank\" rel=\"noopener noreferrer\">https://doi.org/10.1111/camh.12471</a>"
```

**Features:**

- **Supported protocols**: `http://`, `https://`, `ftp://`, and `www.` (automatically prefixed with `https://`)
- **Security attributes**: All links include `target="_blank"` and `rel="noopener noreferrer"`
- **Smart detection**: Won't double-link URLs already in `<a>` tags
- **Multiple URLs**: Handles multiple URLs in the same footnote
- **Punctuation handling**: Excludes trailing punctuation (periods, commas, etc.) from URLs

**Pattern matching:**

The auto-linker uses a sophisticated regex pattern that:
- Matches complete URLs without breaking on query parameters
- Avoids linking URLs that are already part of href attributes
- Handles complex URLs with paths, query strings, and fragments

**Example with multiple URLs:**

```ruby
content = {
  "blocks" => [{
    "type" => "paragraph",
    "data" => {
      "text" => "Research findings",
      "footnotes" => [{
        "id" => "fn-1",
        "content" => "See https://example.com/study and https://doi.org/10.1234/example for details",
        "position" => 17
      }]
    }
  }]
}

renderer = Panda::Editor::Renderer.new(content, autolink_urls: true)
# Both URLs will be converted to clickable links
```

**Disabling auto-linking:**

By default, auto-linking is disabled. Only enable it when needed:

```ruby
# Auto-linking disabled (default)
renderer = Panda::Editor::Renderer.new(content)

# Auto-linking enabled
renderer = Panda::Editor::Renderer.new(content, autolink_urls: true)
```

**Use in Content Concern:**

For applications using the `Panda::Editor::Content` concern, enable auto-linking in the `generate_cached_content` method:

```ruby
def generate_cached_content
  renderer_options = {autolink_urls: true}

  if content.is_a?(Hash) && content["blocks"].present?
    self.cached_content = Panda::Editor::Renderer.new(content, renderer_options).render
  end
end
```

## Tooltips

Footnote markers automatically include tooltip support through two mechanisms:

### Native Browser Tooltips

The `title` attribute provides instant, zero-JavaScript tooltips:

```html
<sup title="IPCC. (2023). Climate Change 2023: Synthesis Report.">
  <a href="#fn:1" class="footnote">1</a>
</sup>
```

This works immediately in all browsers with no additional code required. However, native tooltips have limitations:
- Cannot contain HTML formatting
- Limited styling options
- Inconsistent behavior across browsers

### Custom Tooltips

For richer tooltips, use the `data-footnote-content` attribute with your preferred tooltip library:

**With Tippy.js:**

```javascript
import tippy from 'tippy.js'
import 'tippy.js/dist/tippy.css'

// Initialize tooltips for all footnote markers
tippy('[data-footnote-content]', {
  content: (reference) => reference.getAttribute('data-footnote-content'),
  allowHTML: true,
  theme: 'light',
  placement: 'top',
  maxWidth: 400
})
```

**With Bootstrap:**

```javascript
// Initialize Bootstrap tooltips
document.querySelectorAll('[data-footnote-content]').forEach(element => {
  new bootstrap.Tooltip(element, {
    title: element.getAttribute('data-footnote-content'),
    html: true,
    placement: 'top'
  })
})
```

**With Custom CSS Tooltips:**

```css
/* Pure CSS tooltip */
.footnote-ref {
  position: relative;
}

.footnote-ref::after {
  content: attr(data-footnote-content);
  position: absolute;
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  padding: 0.5rem;
  background: #333;
  color: white;
  border-radius: 0.25rem;
  font-size: 0.875rem;
  white-space: nowrap;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.2s;
  z-index: 1000;
}

.footnote-ref:hover::after {
  opacity: 1;
}
```

**Security Note:** The `data-footnote-content` attribute is properly HTML-escaped to prevent XSS attacks. When using `allowHTML: true` with tooltip libraries, the content is safe because special characters are already escaped.

## CSS Styling

The rendered HTML includes Tailwind CSS classes. You can customize the appearance:

### Default Classes

```html
<!-- Container -->
<div class="mx-6 lg:mx-8 mt-4 mb-8">

<!-- Section wrapper -->
<div class="footnotes-section bg-gray-50 rounded-lg overflow-hidden">

<!-- Toggle button -->
<button class="footnotes-header w-full px-4 py-3 flex items-center justify-between cursor-pointer hover:bg-gray-100 transition-colors">

<!-- Header text -->
<h3 class="text-sm font-unbounded font-medium text-gray-900 m-0">

<!-- Content area -->
<div class="footnotes-content">
  <ol class="footnotes text-sm text-gray-700 space-y-2 px-4 pb-3">
```

### Custom Styling

To customize the appearance, override these classes in your application CSS:

```css
/* Custom container spacing */
.footnotes-section {
  @apply my-12;
}

/* Custom header styling */
.footnotes-header h3 {
  @apply text-lg font-bold;
}

/* Custom footnote list styling */
.footnotes-content ol {
  @apply text-base leading-relaxed;
}

/* Inline footnote markers */
sup.footnote a {
  @apply text-blue-600 hover:text-blue-800;
}
```

## Examples

### Academic Citation

```json
{
  "type": "paragraph",
  "data": {
    "text": "Research shows significant improvements in renewable energy efficiency",
    "footnotes": [{
      "id": "fn-smith-2023",
      "content": "Smith, J., & Jones, M. (2023). Advances in solar panel technology. <em>Journal of Renewable Energy</em>, 45(2), 123-145.",
      "position": 70
    }]
  }
}
```

### Web Resource

```json
{
  "type": "paragraph",
  "data": {
    "text": "According to NASA, global sea levels have risen 8-9 inches since 1880",
    "footnotes": [{
      "id": "fn-nasa-2023",
      "content": "NASA. (2023). <a href=\"https://climate.nasa.gov/vital-signs/sea-level/\" target=\"_blank\">Sea Level Change Data</a>. Retrieved October 26, 2025.",
      "position": 70
    }]
  }
}
```

### Multiple Citations

```json
{
  "type": "paragraph",
  "data": {
    "text": "Studies from 2022 and 2023 confirm these findings",
    "footnotes": [
      {
        "id": "fn-study-2022",
        "content": "Johnson, A. (2022). Early intervention strategies.",
        "position": 18
      },
      {
        "id": "fn-study-2023",
        "content": "Williams, B. (2023). Long-term outcomes.",
        "position": 31
      }
    ]
  }
}
```

## Testing

The footnote system includes comprehensive test coverage:

### Paragraph Block Tests

Located in `spec/lib/panda/editor/blocks/paragraph_spec.rb`:

- ✓ Injects footnote markers at correct positions
- ✓ Registers footnotes with the registry
- ✓ Handles multiple footnotes in correct order
- ✓ Returns same number for duplicate IDs
- ✓ Works without footnotes

### Renderer Tests

Located in `spec/lib/panda/editor/renderer_spec.rb`:

- ✓ Appends sources section when footnotes exist
- ✓ Does not append sources section when no footnotes
- ✓ Handles duplicate footnote IDs correctly
- ✓ Numbers footnotes sequentially across paragraphs

### Running Tests

```bash
cd /path/to/panda-editor
bundle exec rspec spec/lib/panda/editor/blocks/paragraph_spec.rb
bundle exec rspec spec/lib/panda/editor/renderer_spec.rb
```

## Troubleshooting

### Footnote marker not appearing

**Problem**: The superscript marker doesn't show up in the rendered HTML.

**Solutions**:
- Check that `position` is within the text length (0 to text.length)
- Verify the footnote has both `id` and `content` fields
- Ensure the `FootnoteRegistry` is passed in the options

### Wrong footnote number

**Problem**: Footnote shows number 2 when it should be 1.

**Solutions**:
- Check if another footnote is being registered first
- Verify footnote IDs are unique (unless intentionally reusing)
- Review the order of blocks in your JSON

### Sources section not appearing

**Problem**: Inline markers work but no sources section at bottom.

**Solutions**:
- Verify footnotes are actually being registered (check `FootnoteRegistry#any?`)
- Ensure the renderer is calling `render_sources_section`
- Check that blocks are receiving the footnote registry in options

### Position calculation off by one

**Problem**: Footnote appears one character before/after expected position.

**Solutions**:
- Remember positions are zero-indexed
- Position 0 is before the first character
- Position equal to text.length is after the last character
- Test with plain text first, then add HTML formatting

## Future Enhancements

See GitHub issue [#2](https://github.com/tastybamboo/panda-editor/issues/2) for planned improvements including:

- [ ] Support for footnotes in other block types (headers, quotes, etc.)
- [x] Rich text formatting within footnote content (implemented via markdown support)
- [x] Footnote tooltips on hover (implemented with native browser tooltips and custom tooltip data attributes)
- [ ] Customizable footnote markers (*, †, ‡, etc.)
- [ ] Export footnotes to bibliography formats (BibTeX, etc.)
- [ ] Footnote management UI in EditorJS
- [ ] Smart position recalculation when text changes

## License

This documentation is part of Panda Editor, available under the BSD-3-Clause License.

## Contributing

Found a bug or have a suggestion? Please open an issue on GitHub at https://github.com/tastybamboo/panda-editor.
