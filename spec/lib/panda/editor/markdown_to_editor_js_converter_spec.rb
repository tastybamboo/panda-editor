# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Editor::MarkdownToEditorJsConverter do
  describe ".convert" do
    it "converts Markdown to EditorJS format" do
      markdown = "# Test"
      result = described_class.convert(markdown)

      expect(result).to be_a(Hash)
      expect(result[:blocks]).to be_an(Array)
      expect(result[:version]).to eq("2.28.2")
    end

    it "handles empty markdown" do
      result = described_class.convert("")

      expect(result[:blocks]).to be_empty
    end
  end

  describe "#convert" do
    subject { described_class.new(markdown).convert }

    context "with headers" do
      let(:markdown) do
        <<~MD
          # Heading 1
          ## Heading 2
          ### Heading 3
          #### Heading 4
          ##### Heading 5
          ###### Heading 6
        MD
      end

      it "converts headers to EditorJS header blocks" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(6)
        (1..6).each do |level|
          expect(blocks[level - 1]).to include(
            type: "header",
            data: include(level: level)
          )
        end
      end
    end

    context "with paragraphs" do
      let(:markdown) do
        <<~MD
          First paragraph

          Second paragraph
        MD
      end

      it "converts paragraphs to EditorJS paragraph blocks" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(2)
        expect(blocks[0]).to include(
          type: "paragraph",
          data: include(text: /First paragraph/)
        )
        expect(blocks[1]).to include(
          type: "paragraph",
          data: include(text: /Second paragraph/)
        )
      end
    end

    context "with inline formatting" do
      let(:markdown) { "Text with **bold** and *italic* and ~~strikethrough~~" }

      it "converts to HTML tags in EditorJS" do
        blocks = subject[:blocks]

        expect(blocks[0][:data][:text]).to include("<b>bold</b>")
        expect(blocks[0][:data][:text]).to include("<i>italic</i>")
        expect(blocks[0][:data][:text]).to include("<del>strikethrough</del>")
      end
    end

    context "with links" do
      let(:markdown) { "Check out [this link](https://example.com)" }

      it "converts to HTML anchor tags" do
        blocks = subject[:blocks]

        expect(blocks[0][:data][:text]).to include("<a")
        expect(blocks[0][:data][:text]).to include('href="https://example.com"')
        expect(blocks[0][:data][:text]).to include("this link")
      end

      it "preserves link href and text" do
        blocks = subject[:blocks]

        expect(blocks[0][:data][:text]).to include('<a href="https://example.com">this link</a>')
      end
    end

    context "with autolinks" do
      let(:markdown) { "Visit https://example.com for more info" }

      it "automatically converts URLs to links" do
        blocks = subject[:blocks]

        expect(blocks[0][:data][:text]).to include("<a")
        expect(blocks[0][:data][:text]).to include('href="https://example.com"')
      end
    end

    context "with unordered lists" do
      let(:markdown) do
        <<~MD
          - Item 1
          - Item 2
          - Item 3
        MD
      end

      it "converts to EditorJS list block" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: "list",
          data: include(
            style: "unordered",
            items: ["Item 1", "Item 2", "Item 3"]
          )
        )
      end
    end

    context "with ordered lists" do
      let(:markdown) do
        <<~MD
          1. First item
          2. Second item
          3. Third item
        MD
      end

      it "converts to EditorJS ordered list block" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: "list",
          data: include(
            style: "ordered",
            items: ["First item", "Second item", "Third item"]
          )
        )
      end
    end

    context "with blockquotes" do
      let(:markdown) { "> This is a quote" }

      it "converts to EditorJS quote block" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: "quote",
          data: include(
            text: /This is a quote/
          )
        )
      end
    end

    context "with fenced code blocks" do
      let(:markdown) do
        <<~MD
          ```javascript
          const x = 42;
          console.log(x);
          ```
        MD
      end

      it "converts to EditorJS code block" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: "code",
          data: include(
            code: /const x = 42/
          )
        )
      end
    end

    context "with indented code blocks" do
      let(:markdown) do
        <<~MD
          Regular text

              indented code
              more code
        MD
      end

      it "converts to EditorJS code block" do
        blocks = subject[:blocks]

        expect(blocks).to satisfy { |b| b.any? { |block| block[:type] == "code" } }
      end
    end

    context "with tables" do
      let(:markdown) do
        <<~MD
          | Header 1 | Header 2 |
          |----------|----------|
          | Cell 1   | Cell 2   |
          | Cell 3   | Cell 4   |
        MD
      end

      it "converts to EditorJS table block" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: "table",
          data: include(
            withHeadings: true,
            content: be_an(Array)
          )
        )
      end
    end

    context "with horizontal rules" do
      let(:markdown) do
        <<~MD
          Before

          ---

          After
        MD
      end

      it "converts to EditorJS delimiter block" do
        blocks = subject[:blocks]

        expect(blocks).to satisfy { |b|
          b.any? { |block| block[:type] == "delimiter" }
        }
      end
    end

    context "with superscript" do
      let(:markdown) { "E = mc^2" }

      it "converts to superscript HTML" do
        blocks = subject[:blocks]

        expect(blocks[0][:data][:text]).to include("<sup>2</sup>")
      end
    end

    context "with footnotes" do
      let(:markdown) do
        <<~MD
          Text with a footnote[^1].

          [^1]: This is the footnote.
        MD
      end

      it "processes footnotes" do
        expect { subject }.not_to raise_error
        expect(subject[:blocks]).to be_an(Array)
      end

      it "extracts footnotes into paragraph data" do
        blocks = subject[:blocks]
        paragraph = blocks.find { |b| b[:type] == "paragraph" }

        expect(paragraph).not_to be_nil
        expect(paragraph[:data][:text]).not_to include("fnref")
        expect(paragraph[:data][:text]).not_to include("<sup")
        expect(paragraph[:data][:footnotes]).to be_an(Array)
        expect(paragraph[:data][:footnotes].length).to eq(1)
        expect(paragraph[:data][:footnotes][0][:id]).to eq("fn-1")
        expect(paragraph[:data][:footnotes][0][:content]).to include("This is the footnote.")
      end

      it "does not include footnotes div as a separate block" do
        blocks = subject[:blocks]

        expect(blocks.none? { |b| b[:data][:text]&.include?("footnotes") }).to be true
      end
    end

    context "with multiple footnotes" do
      let(:markdown) do
        <<~MD
          First claim[^1] and second claim[^2].

          [^1]: First source.
          [^2]: Second source.
        MD
      end

      it "extracts multiple footnotes" do
        blocks = subject[:blocks]
        paragraph = blocks.find { |b| b[:type] == "paragraph" && b[:data].key?(:footnotes) }

        expect(paragraph[:data][:footnotes].length).to eq(2)
        expect(paragraph[:data][:footnotes][0][:content]).to include("First source.")
        expect(paragraph[:data][:footnotes][1][:content]).to include("Second source.")
      end
    end

    context "with mixed content" do
      let(:markdown) do
        <<~MD
          # Article Title

          This is an introduction paragraph with **bold** and *italic* text.

          ## Section 1

          - Point one
          - Point two
          - Point three

          > A famous quote from someone

          ```ruby
          def hello
            puts "world"
          end
          ```

          ## Conclusion

          Final thoughts with a [link](https://example.com).
        MD
      end

      it "converts all markdown elements correctly" do
        blocks = subject[:blocks]

        expect(blocks).to satisfy { |b| b.any? { |block| block[:type] == "header" } }
        expect(blocks).to satisfy { |b| b.any? { |block| block[:type] == "paragraph" } }
        expect(blocks).to satisfy { |b| b.any? { |block| block[:type] == "list" } }
        expect(blocks).to satisfy { |b| b.any? { |block| block[:type] == "quote" } }
        expect(blocks).to satisfy { |b| b.any? { |block| block[:type] == "code" } }
      end
    end

    context "with edge cases" do
      context "empty string" do
        let(:markdown) { "" }

        it "returns empty blocks" do
          expect(subject[:blocks]).to be_empty
        end
      end

      context "only whitespace" do
        let(:markdown) { "  \n\n  \n  " }

        it "returns empty blocks" do
          expect(subject[:blocks]).to be_empty
        end
      end

      context "special characters" do
        let(:markdown) { 'Text with & < > " characters' }

        it "decodes HTML entities from text nodes" do
          blocks = subject[:blocks]

          expect(blocks[0][:data][:text]).to include("&")
          expect(blocks[0][:data][:text]).to include("<")
          expect(blocks[0][:data][:text]).to include(">")
        end
      end

      context "smart typography" do
        it "converts -- to en dash in paragraph text" do
          result = described_class.new("Some text -- with en dash").convert
          blocks = result[:blocks]

          expect(blocks[0][:data][:text]).to include("\u2013")
          expect(blocks[0][:data][:text]).not_to include("--")
        end

        it "converts --- to em dash in paragraph text" do
          result = described_class.new("Some text --- with em dash").convert
          blocks = result[:blocks]

          expect(blocks[0][:data][:text]).to include("\u2014")
        end

        it "preserves -- in fenced code blocks" do
          markdown = "```\nvalue -- other\n```"
          result = described_class.new(markdown).convert
          blocks = result[:blocks]
          code_block = blocks.find { |b| b[:type] == "code" }

          expect(code_block[:data][:code]).to include("--")
          expect(code_block[:data][:code]).not_to include("\u2013")
        end

        it "preserves -- in inline code" do
          result = described_class.new("Use `x -- y` in your code").convert
          blocks = result[:blocks]

          expect(blocks[0][:data][:text]).to include("<code>x -- y</code>")
        end
      end

      context "hard line breaks" do
        let(:markdown) do
          "Line one  \nLine two"
        end

        it "splits hard line breaks into separate paragraphs" do
          blocks = subject[:blocks]

          expect(blocks.any? { |b| b[:data][:text]&.include?("Line one") }).to be true
          expect(blocks.any? { |b| b[:data][:text]&.include?("Line two") }).to be true
        end
      end

      context "with no_intra_emphasis" do
        let(:markdown) { "some_variable_name" }

        it "does not treat underscores in words as emphasis" do
          blocks = subject[:blocks]

          expect(blocks[0][:data][:text]).to eq("some_variable_name")
        end
      end
    end

    context "integration with HtmlToEditorJsConverter" do
      let(:markdown) { "# Test Header" }

      it "uses HtmlToEditorJsConverter internally" do
        # Verify the conversion pipeline works end-to-end
        expect(Panda::Editor::HtmlToEditorJsConverter).to receive(:convert).and_call_original

        subject
      end
    end

    context "with custom converters" do
      let(:custom_converter) do
        Class.new do
          def self.convert(node)
            return nil unless node.element? && node.name == "blockquote"

            first_p = node.at_css("p")
            return nil unless first_p

            text = first_p.text.strip
            return nil unless text.start_with?("[!CUSTOM]")

            {
              type: "custom_block",
              data: {content: text.sub("[!CUSTOM]", "").strip}
            }
          end
        end
      end

      it "passes custom converters to HtmlToEditorJsConverter" do
        markdown = "> [!CUSTOM] Special content"
        result = described_class.convert(markdown, custom_converters: {"custom" => custom_converter})
        blocks = result[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0][:type]).to eq("custom_block")
        expect(blocks[0][:data][:content]).to eq("Special content")
      end

      it "uses default converters from config when not specified" do
        allow(Panda::Editor.config).to receive(:custom_converters).and_return({})
        expect(Panda::Editor::HtmlToEditorJsConverter).to receive(:convert)
          .with(anything, custom_converters: {})
          .and_call_original

        described_class.convert("# Test")
      end
    end
  end

  describe "error handling" do
    context "with nil input" do
      it "raises TypeError for nil input" do
        expect { described_class.new(nil).convert }.to raise_error(TypeError)
      end
    end

    context "with invalid markdown" do
      let(:markdown) { '<script>alert("xss")</script>' }

      it "handles potentially malicious content" do
        expect { described_class.new(markdown).convert }.not_to raise_error
      end
    end
  end
end
