# frozen_string_literal: true

module Panda
  module Editor
    class HtmlToEditorJsConverter
      class ConversionError < StandardError; end

      def self.convert(html, custom_converters: {})
        return {time: Time.current.to_i * 1000, blocks: [], version: "2.28.2"} if html.blank?

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
        doc = Nokogiri::HTML.fragment(@html.to_s)
        raise ConversionError, "Failed to parse HTML content" unless doc

        extract_footnote_definitions(doc)

        blocks = []
        current_text = ""

        doc.children.each do |node|
          next if footnotes_div?(node)

          # Try custom converters first on every node
          custom_block = try_custom_converters(node)
          if custom_block
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end
            extract_footnotes_from_custom_block(custom_block) if @has_footnotes
            blocks << custom_block
            next
          end

          case node.name
          when "h1", "h2", "h3", "h4", "h5", "h6"
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

            blocks << {
              type: "header",
              data: {
                text: node.inner_html.strip,
                level: node.name[1].to_i
              }
            }
          when "p"
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

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
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

            node.children.each do |child|
              # Try custom converters on div children too
              custom_child_block = try_custom_converters(child)
              if custom_child_block
                blocks << custom_child_block
                next
              end

              case child.name
              when "h1", "h2", "h3", "h4", "h5", "h6"
                blocks << {
                  type: "header",
                  data: {
                    text: child.inner_html.strip,
                    level: child.name[1].to_i
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
                  type: "list",
                  data: {
                    style: (child.name == "ul") ? "unordered" : "ordered",
                    items: items
                  }
                }
              when "blockquote"
                blocks << {
                  type: "quote",
                  data: {
                    text: process_inline_elements(child),
                    caption: "",
                    alignment: "left"
                  }
                }
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
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

            items = node.css("li").map { |li| process_inline_elements(li) }
            next if items.empty?

            blocks << {
              type: "list",
              data: {
                style: (node.name == "ul") ? "unordered" : "ordered",
                items: items
              }
            }
          when "blockquote"
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

            blocks << {
              type: "quote",
              data: {
                text: process_inline_elements(node),
                caption: "",
                alignment: "left"
              }
            }
          when "pre"
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

            code = node.css("code").first
            blocks << {
              type: "code",
              data: {
                code: code ? code.text : node.text
              }
            }
          when "table"
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

            content = node.css("tr").map do |row|
              row.css("th, td").map { |cell| cell.inner_html.strip }
            end

            blocks << {
              type: "table",
              data: {
                withHeadings: node.css("thead").any? || node.css("th").any?,
                content: content
              }
            }
          when "hr"
            if current_text.present?
              blocks << create_paragraph_block(current_text)
              current_text = ""
            end

            blocks << {type: "delimiter", data: {}}
          end
        end

        blocks << create_paragraph_block(current_text) if current_text.present?

        {
          time: Time.current.to_i * 1000,
          blocks: blocks,
          version: "2.28.2"
        }
      rescue ConversionError
        raise
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
          type: "paragraph",
          data: {
            text: text.strip
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

        data = {text: result[:text]}
        data[:footnotes] = result[:footnotes] unless result[:footnotes].empty?

        {
          type: "paragraph",
          data: data
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
                id: "fn-#{fn_id}",
                content: content,
                position: char_position
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

      # Post-process custom block to extract footnote markers from HTML content.
      # Replaces raw <sup id="fnref..."> tags with {{FOOTNOTE:id}} placeholders
      # and adds a footnotes array to the block data.
      def extract_footnotes_from_custom_block(block)
        data = block["data"] || block[:data]
        return unless data

        content = data["content"] || data[:content]
        return unless content.is_a?(String)

        fragment = Nokogiri::HTML.fragment(content)
        sups = fragment.css('sup[id^="fnref"]')
        return if sups.empty?

        footnotes = []
        sups.each do |sup|
          fn_id = sup["id"].to_s.sub(/^fnref/, "")
          fn_content = @footnote_definitions[fn_id]
          next unless fn_content

          footnote_id = "fn-#{fn_id}"
          footnotes << {"id" => footnote_id, "content" => fn_content}
          sup.replace("{{FOOTNOTE:#{footnote_id}}}")
        end

        if footnotes.any?
          content_key = data.key?("content") ? "content" : :content
          data["footnotes"] = footnotes
          data[content_key] = fragment.to_html
        end
      end
    end
  end
end
