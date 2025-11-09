# frozen_string_literal: true

require "nokogiri"

module Panda
  module Editor
    # Converts HTML to EditorJS format
    # Parses HTML and converts it to EditorJS blocks
    class HtmlToEditorJsConverter
      def self.convert(html)
        new(html).convert
      end

      def initialize(html)
        @html = html
        @blocks = []
      end

      def convert
        doc = Nokogiri::HTML.fragment(@html)

        doc.children.each do |node|
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
          # Handle text nodes that aren't wrapped in tags
          text = node.text.strip
          text.empty? ? nil : paragraph_block_from_text(text)
        else
          # For any other node, try to extract text content
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
        style = node.name == "ol" ? "ordered" : "unordered"
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

        # Process table rows
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
    end
  end
end
