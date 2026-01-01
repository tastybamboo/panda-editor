# frozen_string_literal: true

module Panda
  module Editor
    module Blocks
      class List < Base
        def render
          style = data["style"] || data[:style]
          list_type = (style == "ordered") ? "ol" : "ul"
          html_safe(
            "<#{list_type}>" \
            "#{render_items(data["items"] || data[:items] || [])}" \
            "</#{list_type}>"
          )
        end

        private

        def render_items(items)
          return "" unless items.is_a?(Array)

          items.map do |item|
            content = extract_content(item)
            nested_items = extract_nested_items(item)
            nested = nested_items.present? ? render_nested(nested_items) : ""
            "<li>#{sanitize(content.to_s)}#{nested}</li>"
          end.join
        end

        def extract_content(item)
          return item unless item.is_a?(Hash)

          # Handle both string and symbol keys
          item["content"] || item[:content] || ""
        end

        def extract_nested_items(item)
          return [] unless item.is_a?(Hash)

          # Handle both string and symbol keys
          item["items"] || item[:items] || []
        end

        def render_nested(items)
          style = data["style"] || data[:style]
          self.class.new({"items" => items, "style" => style}).render
        end
      end
    end
  end
end
