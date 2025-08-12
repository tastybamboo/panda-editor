# frozen_string_literal: true

require_relative "editor/version"
require_relative "editor/engine"

module Panda
  module Editor
    class Error < StandardError; end

    # Autoload components
    autoload :Renderer, "panda/editor/renderer"
    autoload :Content, "panda/editor/content"
    
    module Blocks
      autoload :Base, "panda/editor/blocks/base"
      autoload :Alert, "panda/editor/blocks/alert"
      autoload :Header, "panda/editor/blocks/header"
      autoload :Image, "panda/editor/blocks/image"
      autoload :List, "panda/editor/blocks/list"
      autoload :Paragraph, "panda/editor/blocks/paragraph"
      autoload :Quote, "panda/editor/blocks/quote"
      autoload :Table, "panda/editor/blocks/table"
    end
  end
end