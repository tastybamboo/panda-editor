# Tool Configuration

Panda Editor allows you to configure which EditorJS tools are available in the editor toolbar, and customize their options.

## Basic Configuration

In your Rails initializer (e.g., `config/initializers/panda_editor.rb`):

```ruby
Panda::Editor.configure do |config|
  config.tools = {
    paragraph: {},
    header: { levels: [2, 3, 4], default_level: 2 },
    list: {},
    quote: {},
    image: {},
    table: {},
    embed: { services: { youtube: true, vimeo: true } },
    link_tool: {},
    attaches: {},
    footnote: {},
    link: {}
  }
end
```

## How It Works

- **Present in hash = enabled**: Any tool key in the hash is loaded in the editor.
- **Absent = disabled**: Remove a key to disable that tool entirely.
- **Options override JS defaults**: Hash values are deep-merged into the tool's JavaScript config.

## Default Tools

All of the following tools are enabled by default:

| Tool Key | EditorJS Tool | Description |
|----------|--------------|-------------|
| `paragraph` | Paragraph | Text content (always recommended) |
| `header` | Header | Headings h1-h6 |
| `list` | NestedList | Ordered/unordered lists |
| `quote` | Quote | Block quotes with captions |
| `image` | ImageTool | Image uploads |
| `table` | Table | Data tables |
| `embed` | Embed | YouTube, Vimeo embeds |
| `link_tool` | LinkTool | Link metadata previews |
| `attaches` | AttachesTool | File attachments |
| `footnote` | FootnoteTool | Inline footnotes |
| `link` | LinkAutocomplete | Link autocomplete |

## Opt-in Tools

These tools ship with the gem but are not enabled by default:

| Tool Key | Description |
|----------|-------------|
| `pdf` | PDF viewer with PDF.js (see [PDF_VIEWER.md](PDF_VIEWER.md)) |

To enable an opt-in tool, add it to your tools configuration:

```ruby
Panda::Editor.configure do |config|
  config.tools = config.tools.merge(pdf: {})
end
```

## Disabling Tools

To disable a default tool, remove it from the hash:

```ruby
Panda::Editor.configure do |config|
  tools = config.tools.dup
  tools.delete(:embed)      # Remove embed tool
  tools.delete(:table)      # Remove table tool
  config.tools = tools
end
```

## Configuring Tool Options

Pass options to customize tool behavior:

```ruby
Panda::Editor.configure do |config|
  config.tools = {
    paragraph: {},
    header: {
      levels: [2, 3],        # Only allow h2 and h3
      default_level: 2       # Default to h2
    },
    table: {
      rows: 3,               # Default 3 rows
      cols: 4                # Default 4 columns
    },
    embed: {
      services: {
        youtube: true,
        vimeo: false          # Disable Vimeo
      }
    }
  }
end
```

Options are converted from Ruby snake_case to JavaScript camelCase automatically (e.g., `default_level` becomes `defaultLevel`).

## Custom Tools via JavaScript

Host applications can still add custom JavaScript-only tools using the existing extension points:

```javascript
// In your application.js
window.PANDA_CMS_EDITOR_JS_CONFIG = {
  myCustomTool: {
    class: MyCustomToolClass,
    config: { /* ... */ }
  }
}
```

This merges after the Ruby config is applied, so custom JS tools work alongside configured tools.
