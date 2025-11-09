# frozen_string_literal: true

require "redcarpet"

module Panda
  module Editor
    # Converts Markdown to EditorJS format
    # Uses Redcarpet to parse markdown to HTML, then converts HTML to EditorJS blocks
    class MarkdownToEditorJsConverter
      def self.convert(markdown)
        new(markdown).convert
      end

      def initialize(markdown)
        @markdown = markdown
      end

      def convert
        # Step 1: Convert Markdown to HTML using Redcarpet
        html = markdown_to_html

        # Step 2: Convert HTML to EditorJS using existing converter
        Panda::Editor::HtmlToEditorJsConverter.convert(html)
      end

      private

      def markdown_to_html
        renderer = Redcarpet::Render::HTML.new(
          hard_wrap: true,
          link_attributes: {rel: "noopener noreferrer"}
        )

        markdown_processor = Redcarpet::Markdown.new(
          renderer,
          autolink: true,
          tables: true,
          fenced_code_blocks: true,
          strikethrough: true,
          superscript: true,
          footnotes: true,
          no_intra_emphasis: true,
          space_after_headers: true
        )

        markdown_processor.render(@markdown)
      end
    end
  end
end
