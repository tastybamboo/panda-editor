# frozen_string_literal: true

module Panda
  module Editor
    module Blocks
      class Paragraph < Base
        def render
          content = sanitize(data["text"])
          return "" if content.blank?

          html_safe("<p>#{content}</p>")
        end
      end
    end
  end
end
