# frozen_string_literal: true

require "dry-configurable"
require_relative "editor/version"
require_relative "editor/engine"

module Panda
  module Editor
    extend Dry::Configurable

    mattr_accessor :importmap

    # EditorJS configuration
    setting :editor_js_tools, default: []
    setting :editor_js_tool_config, default: {}

    # Custom block renderers
    setting :custom_renderers, default: {}

    class Error < StandardError; end

    # Require components
    require_relative "editor/renderer"
    require_relative "editor/content"
    require_relative "editor/footnote_registry"
    require_relative "editor/markdown_to_editor_js_converter"
    require_relative "editor/html_to_editor_js_converter"

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
      autoload :Table, "panda/editor/blocks/table"
    end
  end
end
