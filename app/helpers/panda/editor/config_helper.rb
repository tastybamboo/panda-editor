# frozen_string_literal: true

module Panda
  module Editor
    module ConfigHelper
      def panda_editor_tools_config_json
        Panda::Editor::ToolsConfigSerializer.new(Panda::Editor.config.tools).to_json
      end
    end
  end
end
