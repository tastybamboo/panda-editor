# frozen_string_literal: true

module Panda
  module Editor
    class HtmlToEditorJsConverter
      class ConversionError < StandardError; end

      def self.convert(html, custom_converters: {})
        return {} if html.blank?

        # If it's already in EditorJS format, return as is
        return html if html.is_a?(Hash) && (html["blocks"].present? || html[:blocks].present?)

        new(html, custom_converters: custom_converters).convert
      end

      def initialize(html, custom_converters: {})
        @html = html
        @custom_converters = custom_converters
        @footnote_definitions = {}
        @has_footnotes = false
      end

      def convert
        # Parse the HTML content
        doc = Nokogiri::HTML.fragment(@html.to_s)
        raise ConversionError, "Failed to parse HTML content" unless doc

        extract_footnote_definitions(doc)

        blocks = []
        current_text = ""

        doc.children.each do |node|
          next if footnotes_div?(node)

          case node.name
          when "h1", "h2", "h3", "h4", "h5", "h6"
            # Add any accumulated text as a paragraph before the header
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

            blocks << {
              "type" => "header",
              "data" => {
                "text" => node.text.strip,
                "level" => node.name[1].to_i
              }
            }
          when "p"
            # Add any accumulated text first
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

            # Check for custom converter match
            custom_block = try_custom_converters(node)
            if custom_block
              blocks << custom_block
              next
            end

            # Check for footnote references
            if @has_footnotes && node.at_css('sup[id^="fnref"]')
              block = paragraph_block_with_footnotes(node)
              blocks << block if block
            else
              text = process_inline_elements(node)
              paragraphs = text.split(%r{<br\s*/?>\s*<br\s*/?>}).map(&:strip)
              paragraphs.each do |paragraph|
                blocks << create_paragraph_block(paragraph) if paragraph.present?
              end
            end
          when "div"
            # Add any accumulated text first
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

            # Process div children separately
            node.children.each do |child|
              case child.name
              when "h1", "h2", "h3", "h4", "h5", "h6"
                blocks << {
                  "type" => "header",
                  "data" => {
                    "text" => child.text.strip,
                    "level" => child.name[1].to_i
                  }
                }
              when "p"
                text = process_inline_elements(child)
                paragraphs = text.split(%r{<br\s*/?>\s*<br\s*/?>}).map(&:strip)
                paragraphs.each do |paragraph|
                  blocks << create_paragraph_block(paragraph) if paragraph.present?
                end
              when "ul", "ol"
                items = child.css("li").map { |li| process_inline_elements(li) }
                next if items.empty?

                blocks << {
                  "type" => "list",
                  "data" => {
                    "style" => (child.name == "ul") ? "unordered" : "ordered",
                    "items" => items
                  }
                }
              when "blockquote"
                custom_block = try_custom_converters(child)
                if custom_block
                  blocks << custom_block
                else
                  blocks << {
                    "type" => "quote",
                    "data" => {
                      "text" => process_inline_elements(child),
                      "caption" => "",
                      "alignment" => "left"
                    }
                  }
                end
              when "text"
                text = child.text.strip
                current_text += text if text.present?
              end
            end
          when "br"
            current_text += "\n\n"
          when "text"
            text = node.text.strip
            current_text += text if text.present?
          when "ul", "ol"
            # Add any accumulated text first
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

            items = node.css("li").map { |li| process_inline_elements(li) }
            next if items.empty?

            blocks << {
              "type" => "list",
              "data" => {
                "style" => (node.name == "ul") ? "unordered" : "ordered",
                "items" => items
              }
            }
          when "blockquote"
            # Add any accumulated text first
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

            # Try custom converters first
            custom_block = try_custom_converters(node)
            if custom_block
              blocks << custom_block
            else
              blocks << {
                "type" => "quote",
                "data" => {
                  "text" => process_inline_elements(node),
                  "caption" => "",
                  "alignment" => "left"
                }
              }
            end
          end
        end

        # Add any remaining text
        blocks << create_paragraph_block(current_text) if current_text.present?

        # Return the complete EditorJS structure
        {
          "time" => Time.current.to_i * 1000,
          "blocks" => blocks,
          "version" => "2.28.2"
        }
      rescue => e
        Rails.logger.error "HTML to EditorJS conversion failed: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise ConversionError, "Failed to convert HTML to EditorJS format: #{e.message}"
      end

      private

      def try_custom_converters(node)
        @custom_converters.each_value do |converter|
          result = converter.convert(node)
          return result if result
        end
        nil
      end

      def create_paragraph_block(text)
        {
          "type" => "paragraph",
          "data" => {
            "text" => text.strip
          }
        }
      end

      def process_inline_elements(node)
        result = ""
        node.children.each do |child|
          case child.name
          when "br"
            result += "<br>"
          when "text"
            result += child.text
          when "strong", "b"
            result += "<b>#{child.text}</b>"
          when "em", "i"
            result += "<i>#{child.text}</i>"
          when "a"
            href = child["href"]
            text = child.text.strip
            if href&.start_with?("mailto:")
              email = href.sub("mailto:", "")
              result += "<a href=\"mailto:#{email}\">#{text}</a>"
            else
              result += "<a href=\"#{href}\">#{text}</a>"
            end
          else
            result += if child.text?
              child.text
            else
              child.to_html
            end
          end
        end
        result.strip
      end

      # --- Footnote extraction ---

      def extract_footnote_definitions(doc)
        footnotes_div = doc.at_css("div.footnotes")
        return unless footnotes_div

        @has_footnotes = true

        footnotes_div.css("li[id^='fn']").each do |li|
          fn_id = li["id"].to_s.sub(/^fn/, "")
          next if fn_id.empty?

          content = extract_footnote_content(li)
          @footnote_definitions[fn_id] = content
        end

        footnotes_div.remove
      end

      def extract_footnote_content(li)
        li_clone = li.dup
        li_clone.css("a[href^='#fnref']").each(&:remove)

        text = if (p_node = li_clone.at_css("p"))
          p_node.inner_html.strip
        else
          li_clone.inner_html.strip
        end

        text.gsub(/\u00A0\s*$/, "").gsub(/&nbsp;\s*$/, "").strip
      end

      def footnotes_div?(node)
        node.element? && node.name == "div" && node["class"].to_s.include?("footnotes")
      end

      def paragraph_block_with_footnotes(node)
        result = extract_footnotes_from_paragraph(node)
        return nil if result[:text].empty?

        data = {"text" => result[:text]}
        data["footnotes"] = result[:footnotes] unless result[:footnotes].empty?

        {
          "type" => "paragraph",
          "data" => data
        }
      end

      def extract_footnotes_from_paragraph(node)
        footnotes = []
        text_parts = []
        char_position = 0

        node.children.each do |child|
          if child.element? && child.name == "sup" && child["id"].to_s.start_with?("fnref")
            fn_id = child["id"].to_s.sub(/^fnref/, "")
            content = @footnote_definitions[fn_id]

            if content
              footnotes << {
                "id" => "fn-#{fn_id}",
                "content" => content,
                "position" => char_position
              }
            end
          else
            html_fragment = child.to_html
            text_parts << html_fragment
            char_position += plain_text_length(child)
          end
        end

        {
          text: text_parts.join.strip,
          footnotes: footnotes
        }
      end

      def plain_text_length(node)
        if node.text?
          node.text.length
        else
          node.children.sum { |child| plain_text_length(child) }
        end
      end
    end
  end
end
