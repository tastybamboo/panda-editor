# frozen_string_literal: true

module Panda
  module Editor
    # Serializes the Ruby tools configuration hash to JSON
    # suitable for consumption by the EditorJS JavaScript layer.
    #
    # Handles key mapping between Ruby conventions (snake_case symbols)
    # and JavaScript conventions (camelCase strings).
    class ToolsConfigSerializer
      # Maps Ruby tool names to their EditorJS JavaScript identifiers
      TOOL_NAME_MAP = {
        link_tool: "linkTool"
      }.freeze

      def initialize(tools)
        @tools = tools
      end

      def to_json(*_args)
        serialize.to_json
      end

      def serialize
        @tools.each_with_object({}) do |(tool_name, options), result|
          js_name = TOOL_NAME_MAP[tool_name] || tool_name.to_s
          result[js_name] = deep_camelize_keys(options)
        end
      end

      private

      def deep_camelize_keys(obj)
        case obj
        when Hash
          obj.each_with_object({}) do |(key, value), result|
            camel_key = key.to_s.gsub(/_([a-z])/) { $1.upcase }
            result[camel_key] = deep_camelize_keys(value)
          end
        when Array
          obj.map { |item| deep_camelize_keys(item) }
        else
          obj
        end
      end
    end
  end
end
