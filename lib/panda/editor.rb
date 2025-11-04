# frozen_string_literal: true

require 'dry-configurable'
require_relative 'editor/version'
require_relative 'editor/engine'

module Panda
  module Editor
    extend Dry::Configurable

    # EditorJS configuration
    setting :editor_js_tools, default: []
    setting :editor_js_tool_config, default: {}

    # Custom block renderers
    setting :custom_renderers, default: {}

    class Error < StandardError; end

    # Autoload components
    autoload :Renderer, 'panda/editor/renderer'
    autoload :Content, 'panda/editor/content'
    autoload :FootnoteRegistry, 'panda/editor/footnote_registry'

    module Blocks
      autoload :Base, 'panda/editor/blocks/base'
      autoload :Alert, 'panda/editor/blocks/alert'
      autoload :Header, 'panda/editor/blocks/header'
      autoload :Image, 'panda/editor/blocks/image'
      autoload :List, 'panda/editor/blocks/list'
      autoload :Paragraph, 'panda/editor/blocks/paragraph'
      autoload :Quote, 'panda/editor/blocks/quote'
      autoload :Table, 'panda/editor/blocks/table'
    end
  end
end
