# frozen_string_literal: true

module Panda
  module Editor
    module Blocks
      class Paragraph < Base
        def render
          content = sanitize(data['text'])
          return '' if content.blank?

          content = inject_footnotes(content) if data['footnotes'].present?

          html_safe("<p>#{content}</p>")
        end

        private

        def inject_footnotes(text)
          return text unless data['footnotes'].is_a?(Array)

          # Sort footnotes by position in descending order to avoid position shifts
          footnotes = data['footnotes'].sort_by { |fn| -fn['position'].to_i }

          footnotes.each do |footnote|
            position = footnote['position'].to_i
            # Skip if position is beyond text length
            next if position.negative? || position > text.length

            # Register footnote with renderer's footnote registry
            footnote_number = register_footnote(footnote)
            next unless footnote_number

            # Create footnote marker
            marker = "<sup id=\"fnref:#{footnote_number}\"><a href=\"#fn:#{footnote_number}\" class=\"footnote\">#{footnote_number}</a></sup>"

            # Insert marker at position
            text.insert(position, marker)
          end

          text
        end

        def register_footnote(footnote)
          return nil unless options[:footnote_registry]

          options[:footnote_registry].add(
            id: footnote['id'],
            content: footnote['content']
          )
        end
      end
    end
  end
end
