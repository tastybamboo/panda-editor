# frozen_string_literal: true

require "nokogiri"

module Panda
  module Editor
    # Converts HTML to EditorJS format
    # Parses HTML and converts it to EditorJS blocks
    class HtmlToEditorJsConverter
      def self.convert(html, custom_converters: {})
        new(html, custom_converters: custom_converters).convert
      end

      def initialize(html, custom_converters: {})
        @html = html
        @blocks = []
        @custom_converters = custom_converters
        @footnote_definitions = {}
        @has_footnotes = false
      end

      def convert
        doc = Nokogiri::HTML.fragment(@html)

        extract_footnote_definitions(doc)

        doc.children.each do |node|
          next if footnotes_div?(node)

          block = node_to_block(node)
          @blocks << block if block
        end

        {
          time: Time.now.to_i * 1000,
          blocks: @blocks,
          version: "2.28.0"
        }
      end

      private

      def node_to_block(node)
        return nil if node.text? && node.text.strip.empty?

        # Try custom converters first
        @custom_converters.each_value do |converter|
          result = converter.convert(node)
          return result if result
        end

        case node.name
        when "h1", "h2", "h3", "h4", "h5", "h6"
          header_block(node)
        when "p"
          paragraph_block(node)
        when "ul", "ol"
          list_block(node)
        when "blockquote"
          quote_block(node)
        when "pre"
          code_block(node)
        when "table"
          table_block(node)
        when "hr"
          delimiter_block
        when "text"
          text = node.text.strip
          text.empty? ? nil : paragraph_block_from_text(text)
        else
          text = node.text.strip
          text.empty? ? nil : paragraph_block_from_text(text)
        end
      end

      def header_block(node)
        level = node.name[1].to_i
        {
          type: "header",
          data: {
            text: node.inner_html.strip,
            level: level
          }
        }
      end

      def paragraph_block(node)
        # Check if paragraph contains footnote references
        if @has_footnotes && node.at_css('sup[id^="fnref"]')
          return paragraph_block_with_footnotes(node)
        end

        text = node.inner_html.strip
        return nil if text.empty?

        {
          type: "paragraph",
          data: {
            text: text
          }
        }
      end

      def paragraph_block_from_text(text)
        {
          type: "paragraph",
          data: {
            text: text
          }
        }
      end

      def list_block(node)
        style = (node.name == "ol") ? "ordered" : "unordered"
        items = node.css("li").map { |li| li.inner_html.strip }

        {
          type: "list",
          data: {
            style: style,
            items: items
          }
        }
      end

      def quote_block(node)
        {
          type: "quote",
          data: {
            text: node.inner_html.strip,
            caption: "",
            alignment: "left"
          }
        }
      end

      def code_block(node)
        code = node.css("code").first
        text = code ? code.text : node.text

        {
          type: "code",
          data: {
            code: text
          }
        }
      end

      def table_block(node)
        content = []

        node.css("tr").each do |row|
          cells = row.css("th, td").map { |cell| cell.inner_html.strip }
          content << cells
        end

        {
          type: "table",
          data: {
            withHeadings: node.css("thead").any? || node.css("th").any?,
            content: content
          }
        }
      end

      def delimiter_block
        {
          type: "delimiter",
          data: {}
        }
      end

      # --- Footnote extraction ---

      def extract_footnote_definitions(doc)
        footnotes_div = doc.at_css("div.footnotes")
        return unless footnotes_div

        @has_footnotes = true

        footnotes_div.css("li[id^='fn']").each do |li|
          # Extract the footnote number from the id (e.g. "fn1" -> "1")
          fn_id = li["id"].to_s.sub(/^fn/, "")
          next if fn_id.empty?

          # Get the content, stripping the back-reference link
          content = extract_footnote_content(li)
          @footnote_definitions[fn_id] = content
        end

        # Remove the footnotes div from the DOM so it's not processed as a block
        footnotes_div.remove
      end

      def extract_footnote_content(li)
        # Clone the node so we don't modify the original during iteration
        li_clone = li.dup

        # Remove back-reference links (the ↩ link)
        li_clone.css("a[href^='#fnref']").each(&:remove)

        # Get inner text, cleaning up whitespace and the &nbsp; before the back-ref
        text = if (p_node = li_clone.at_css("p"))
          p_node.inner_html.strip
        else
          li_clone.inner_html.strip
        end

        # Clean trailing &nbsp; and whitespace
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
            # This is a footnote reference
            fn_id = child["id"].to_s.sub(/^fnref/, "")
            content = @footnote_definitions[fn_id]

            if content
              footnotes << {
                id: "fn-#{fn_id}",
                content: content,
                position: char_position
              }
            end
            # Don't add the <sup> to the output text
          else
            # Accumulate text/HTML content and track plain text length
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
