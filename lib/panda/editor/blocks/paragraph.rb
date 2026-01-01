# frozen_string_literal: true

require "cgi"

module Panda
  module Editor
    module Blocks
      class Paragraph < Base
        def render
          content = sanitize(data["text"])
          return "" if content.blank?

          content = inject_footnotes(content) if data["footnotes"].present?

          html_safe("<p>#{content}</p>")
        end

        private

        def inject_footnotes(text)
          return text unless data["footnotes"].is_a?(Array)

          # Sort footnotes by position in descending order to avoid position shifts
          footnotes = data["footnotes"].sort_by { |fn| -fn["position"].to_i }

          footnotes.each do |footnote|
            position = footnote["position"].to_i
            # Skip if position is beyond text length
            next if position.negative? || position > text.length

            # Register footnote with renderer's footnote registry
            footnote_number = register_footnote(footnote)
            next unless footnote_number

            # Get processed content for tooltip
            tooltip_content = get_tooltip_content(footnote["id"])

            # Create footnote marker with tooltip support
            marker = create_footnote_marker(footnote_number, tooltip_content)

            # Insert marker at position
            text.insert(position, marker)
          end

          text
        end

        def register_footnote(footnote)
          return nil unless options[:footnote_registry]

          options[:footnote_registry].add(
            id: footnote["id"],
            content: footnote["content"]
          )
        end

        def get_tooltip_content(footnote_id)
          return nil unless options[:footnote_registry]

          options[:footnote_registry].get_content(footnote_id)
        end

        def create_footnote_marker(number, tooltip_content)
          # Strip HTML tags for title attribute (simple tooltip fallback)
          plain_content = tooltip_content ? strip_html(tooltip_content) : nil

          # Build marker with tooltip support
          if tooltip_content
            # Include both title attribute (native browser tooltip) and data attribute (for custom tooltips)
            escaped_content = CGI.escapeHTML(tooltip_content)
            escaped_title = CGI.escapeHTML(plain_content || "")
            %(<sup id="fnref:#{number}" class="footnote-ref" data-footnote-content="#{escaped_content}" title="#{escaped_title}"><a href="#fn:#{number}" class="footnote">#{number}</a></sup>)
          else
            # Fallback without tooltip
            %(<sup id="fnref:#{number}"><a href="#fn:#{number}" class="footnote">#{number}</a></sup>)
          end
        end

        def strip_html(html)
          html.gsub(/<\/?[^>]*>/, "")
        end
      end
    end
  end
end
