# Panda Editor

A modular, extensible rich text editor using EditorJS for Rails applications. Extracted from [Panda CMS](https://github.com/tastybamboo/panda-cms).

## Features

- 🎨 **Rich Content Blocks**: Paragraph, Header, List, Quote, Table, Image, Alert, and more
- 🔧 **Extensible Architecture**: Easy to add custom block types
- 🚀 **Rails Integration**: Works seamlessly with Rails 7.1+
- 💾 **Smart Caching**: Automatic HTML caching for performance
- 🎯 **Clean API**: Simple concern-based integration for ActiveRecord models

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'panda-editor'
```

And then execute:

```bash
bundle install
```

## Usage

### Basic Setup

Include the concern in your model:

```ruby
class Post < ApplicationRecord
  include Panda::Editor::Content
end
```

This adds:
- `content` field for storing EditorJS JSON
- `cached_content` field for storing rendered HTML
- Automatic HTML generation on save

### Rendering Content

```ruby
# In your controller
@post = Post.find(params[:id])

# In your view
<%= raw @post.cached_content %>

# Or render directly from JSON
renderer = Panda::Editor::Renderer.new(@post.content)
<%= raw renderer.render %>
```

### Converting Content to EditorJS

Panda Editor includes converters for importing existing HTML or Markdown content into EditorJS format:

#### From HTML

```ruby
html = '<h1>Article Title</h1><p>Introduction with <strong>bold</strong> text.</p><ul><li>Point 1</li><li>Point 2</li></ul>'
editor_data = Panda::Editor::HtmlToEditorJsConverter.convert(html)

# Save to your model
@post.content = editor_data
@post.save
```

**Supported HTML elements:**

- Headers (h1-h6)
- Paragraphs with inline formatting (bold, italic, links, etc.)
- Ordered and unordered lists
- Blockquotes
- Code blocks (pre/code)
- Tables (with or without headers)
- Horizontal rules (converted to delimiters)

#### From Markdown

```ruby
markdown = <<~MD
  # Article Title

  Introduction with **bold** and *italic* text.

  - Point 1
  - Point 2

  > A famous quote

  ```ruby
  def hello
    puts "world"
  end
  ```
MD

editor_data = Panda::Editor::MarkdownToEditorJsConverter.convert(markdown)

# Save to your model
@post.content = editor_data
@post.save
```

**Supported Markdown features:**

- Headers (# through ######)
- Paragraphs with inline formatting (\*\*bold\*\*, \*italic\*, \`code\`, \~\~strikethrough\~\~)
- Links (with automatic noopener/noreferrer for security)
- Ordered and unordered lists
- Blockquotes
- Fenced and indented code blocks
- Tables (GitHub-flavored markdown)
- Horizontal rules
- Superscript (^2)
- Footnotes
- Automatic URL linking

Both converters return a hash in EditorJS format that can be saved directly to your content field.

### JavaScript Integration

In your application.js:

```javascript
import { EditorJSInitializer } from "panda/editor"

// Initialize an editor
const element = document.querySelector("#editor")
const editor = new EditorJSInitializer(element, {
  data: existingContent,
  onSave: (data) => {
    // Handle save
  }
})
```

### Custom Block Types

Create a custom block:

```ruby
class CustomBlock < Panda::Editor::Blocks::Base
  def render
    html_safe("<div class='custom'>#{sanitize(data['text'])}</div>")
  end
end

# Register it
Panda::Editor::Engine.config.custom_renderers['custom'] = CustomBlock
```

## Available Blocks

- **Paragraph**: Standard text content
  - Supports inline footnotes with automatic numbering
- **Header**: H1-H6 headings
- **List**: Ordered and unordered lists
- **Quote**: Blockquotes with captions
- **Table**: Tables with optional headers
- **Image**: Images with captions and styling options
- **Alert**: Alert/notification boxes

## Footnotes

Panda Editor supports inline footnotes that are automatically collected and rendered in a "Sources/References" section at the end of your content.

### Adding Footnotes to Paragraphs

Footnotes are added to paragraph blocks in your EditorJS JSON:

```json
{
  "type": "paragraph",
  "data": {
    "text": "Climate change has accelerated significantly since 1980",
    "footnotes": [
      {
        "id": "unique-id-1",
        "content": "IPCC. (2023). Climate Change 2023: Synthesis Report.",
        "position": 55
      }
    ]
  }
}
```

**Fields:**
- `id`: Unique identifier for the footnote (allows multiple citations of the same source)
- `content`: The footnote text/citation
- `position`: Character position in the text where the footnote marker should appear

### Rendered Output

The renderer will:
1. Insert superscript footnote markers (`¹`, `²`, etc.) at specified positions
2. Auto-number footnotes sequentially across the entire document
3. De-duplicate footnotes with the same `id`
4. Generate a collapsible "Sources/References" section at the end

Example output:

```html
<p>Climate change has accelerated significantly since 1980<sup id="fnref:1"><a href="#fn:1" class="footnote">1</a></sup></p>

<!-- Sources section automatically appended -->
<div class="footnotes-section">
  <button class="footnotes-header">
    <h3>Sources/References</h3>
  </button>
  <div class="footnotes-content">
    <ol class="footnotes">
      <li id="fn:1">
        <p>
          IPCC. (2023). Climate Change 2023: Synthesis Report.
          <a href="#fnref:1" class="footnote-backref">↩</a>
        </p>
      </li>
    </ol>
  </div>
</div>
```

### Frontend Integration

The sources section includes data attributes for integration with JavaScript frameworks like Stimulus:

- `data-footnotes-target="toggle"` - Toggle button
- `data-footnotes-target="content"` - Collapsible content
- `data-footnotes-target="chevron"` - Chevron icon for rotation

See [docs/FOOTNOTES.md](docs/FOOTNOTES.md) for detailed implementation examples.

### Markdown Support

Enable markdown formatting in footnote content for rich text citations:

```ruby
renderer = Panda::Editor::Renderer.new(@content, markdown: true)
html = renderer.render
```

Supports **bold**, *italic*, `code`, ~~strikethrough~~, and [links](url):

**Input:**
```
Smith, J. (2023). **Important study** on *ADHD treatment*. See https://example.com for details.
```

**Output:**
```html
Smith, J. (2023). <strong>Important study</strong> on <em>ADHD treatment</em>. See <a href="https://example.com" target="_blank" rel="noopener noreferrer">https://example.com</a> for details.
```

### Auto-linking URLs

Enable automatic URL linking in footnote content:

```ruby
renderer = Panda::Editor::Renderer.new(@content, autolink_urls: true)
html = renderer.render
```

When enabled, plain URLs in footnotes are automatically converted to clickable links:

**Input:**
```
Study by Ward et al. (2021). https://doi.org/10.1111/camh.12471
```

**Output:**
```html
Study by Ward et al. (2021). <a href="https://doi.org/10.1111/camh.12471" target="_blank" rel="noopener noreferrer">https://doi.org/10.1111/camh.12471</a>
```

Features:
- Opens links in new tab with `target="_blank"`
- Includes `rel="noopener noreferrer"` for security
- Won't double-link URLs already in `<a>` tags
- Supports `http://`, `https://`, `ftp://`, and `www.` URLs
- Handles multiple URLs in the same footnote
- Can be combined with `markdown: true` (markdown's autolink runs first, then custom autolink for any remaining URLs)

**Note:** When using `markdown: true`, you typically don't need `autolink_urls: true` as markdown includes built-in autolinking. However, both options can work together safely.

To enable globally for all content using the `Panda::Editor::Content` concern, pass the option in `generate_cached_content`.

## Configuration

```ruby
# config/initializers/panda_editor.rb
Panda::Editor::Engine.configure do |config|
  # Add custom EditorJS tools
  config.editor_js_tools = ['customTool']
  
  # Register custom renderers
  config.custom_renderers = {
    'customBlock' => MyCustomBlockRenderer
  }
end
```

## Assets

### Development
Uses Rails importmaps for individual module loading.

### Production
Compiled assets are automatically downloaded from GitHub releases or can be compiled locally:

```bash
rake panda_editor:assets:compile
```

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tastybamboo/panda-editor.

## License

The gem is available as open source under the terms of the [BSD-3-Clause License](https://opensource.org/licenses/BSD-3-Clause).

## Copyright

Copyright © 2024, Otaina Limited