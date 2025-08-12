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
- **Header**: H1-H6 headings
- **List**: Ordered and unordered lists
- **Quote**: Blockquotes with captions
- **Table**: Tables with optional headers
- **Image**: Images with captions and styling options
- **Alert**: Alert/notification boxes

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