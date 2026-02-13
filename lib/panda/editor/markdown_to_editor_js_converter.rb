# frozen_string_literal: true

require "redcarpet"

module Panda
  module Editor
    # Converts Markdown to EditorJS format
    # Uses Redcarpet to parse markdown to HTML, then converts HTML to EditorJS blocks
    class MarkdownToEditorJsConverter
      def self.convert(markdown, custom_converters: nil)
        new(markdown, custom_converters: custom_converters).convert
      end

      def initialize(markdown, custom_converters: nil)
        @markdown = markdown
        @custom_converters = custom_converters
      end

      def convert
        # Step 1: Convert Markdown to HTML using Redcarpet
        html = markdown_to_html

        # Step 2: Convert HTML to EditorJS using existing converter
        converters = @custom_converters || Panda::Editor.config.custom_converters
        Panda::Editor::HtmlToEditorJsConverter.convert(html, custom_converters: converters)
      end

      private

      def markdown_to_html
        renderer = Redcarpet::Render::SmartyHTML.new(
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
