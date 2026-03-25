# frozen_string_literal: true

require "dry-configurable"
require_relative "editor/version"
require_relative "editor/engine"

module Panda
  module Editor
    extend Dry::Configurable

    mattr_accessor :importmap

    # EditorJS tool configuration
    # Keys = tool names (present = enabled, absent = disabled)
    # Values = option overrides merged into the JS tool config
    setting :tools, default: {
      paragraph: {},
      header: {levels: [1, 2, 3, 4, 5, 6], default_level: 2},
      list: {default_style: "unordered"},
      quote: {},
      image: {},
      table: {rows: 2, cols: 2},
      embed: {services: {youtube: true, vimeo: true}},
      link_tool: {},
      attaches: {},
      footnote: {},
      link: {}
    }

    # Custom block renderers (EditorJS -> HTML)
    setting :custom_renderers, default: {}

    # Custom block converters (HTML -> EditorJS)
    setting :custom_converters, default: {}

    class Error < StandardError; end

    # Require components
    require_relative "editor/tools_config_serializer"
    require_relative "editor/renderer"
    require_relative "editor/content"
    require_relative "editor/footnote_registry"
    require_relative "editor/markdown_to_editor_js_converter"

    module Blocks
      autoload :Base, "panda/editor/blocks/base"
      autoload :Alert, "panda/editor/blocks/alert"
      autoload :Attaches, "panda/editor/blocks/attaches"
      autoload :Header, "panda/editor/blocks/header"
      autoload :Image, "panda/editor/blocks/image"
      autoload :LinkTool, "panda/editor/blocks/link_tool"
      autoload :List, "panda/editor/blocks/list"
      autoload :Paragraph, "panda/editor/blocks/paragraph"
      autoload :Quote, "panda/editor/blocks/quote"
      autoload :Pdf, "panda/editor/blocks/pdf"
      autoload :Table, "panda/editor/blocks/table"
    end
  end
end
