# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Editor::HtmlToEditorJsConverter do
  describe ".convert" do
    it "converts HTML to EditorJS format" do
      html = "<h1>Test</h1>"
      result = described_class.convert(html)

      expect(result).to be_a(Hash)
      expect(result[:blocks]).to be_an(Array)
      expect(result[:version]).to eq("2.28.0")
      expect(result[:time]).to be_a(Integer)
    end

    it "handles empty HTML" do
      result = described_class.convert("")

      expect(result[:blocks]).to be_empty
    end

    it "handles nil input gracefully" do
      result = described_class.convert(nil)

      expect(result[:blocks]).to be_empty
    end
  end

  describe "#convert" do
    subject { described_class.new(html).convert }

    context "with headers" do
      let(:html) { "<h1>Heading 1</h1><h2>Heading 2</h2><h3>Heading 3</h3>" }

      it "converts headers to EditorJS header blocks" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(3)
        expect(blocks[0]).to include(
          type: "header",
          data: {
            text: "Heading 1",
            level: 1
          }
        )
        expect(blocks[1]).to include(
          type: "header",
          data: {
            text: "Heading 2",
            level: 2
          }
        )
        expect(blocks[2]).to include(
          type: "header",
          data: {
            text: "Heading 3",
            level: 3
          }
        )
      end
    end

    context "with paragraphs" do
      let(:html) { "<p>First paragraph</p><p>Second paragraph</p>" }

      it "converts paragraphs to EditorJS paragraph blocks" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(2)
        expect(blocks[0]).to include(
          type: "paragraph",
          data: {
            text: "First paragraph"
          }
        )
        expect(blocks[1]).to include(
          type: "paragraph",
          data: {
            text: "Second paragraph"
          }
        )
      end

      context "with formatting" do
        let(:html) { "<p>Text with <strong>bold</strong> and <em>italic</em></p>" }

        it "preserves HTML formatting" do
          blocks = subject[:blocks]

          expect(blocks[0][:data][:text]).to eq("Text with <strong>bold</strong> and <em>italic</em>")
        end
      end

      context "with links" do
        let(:html) { '<p>Text with <a href="https://example.com">a link</a></p>' }

        it "preserves links" do
          blocks = subject[:blocks]

          expect(blocks[0][:data][:text]).to include('<a href="https://example.com">a link</a>')
        end
      end
    end

    context "with lists" do
      context "unordered lists" do
        let(:html) { "<ul><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul>" }

        it "converts to EditorJS list block" do
          blocks = subject[:blocks]

          expect(blocks.length).to eq(1)
          expect(blocks[0]).to include(
            type: "list",
            data: {
              style: "unordered",
              items: ["Item 1", "Item 2", "Item 3"]
            }
          )
        end
      end

      context "ordered lists" do
        let(:html) { "<ol><li>First</li><li>Second</li><li>Third</li></ol>" }

        it "converts to EditorJS ordered list block" do
          blocks = subject[:blocks]

          expect(blocks.length).to eq(1)
          expect(blocks[0]).to include(
            type: "list",
            data: {
              style: "ordered",
              items: ["First", "Second", "Third"]
            }
          )
        end
      end

      context "with nested HTML in list items" do
        let(:html) { "<ul><li>Item with <strong>bold</strong></li><li>Item with <em>italic</em></li></ul>" }

        it "preserves HTML formatting in list items" do
          blocks = subject[:blocks]

          expect(blocks[0][:data][:items]).to eq([
            "Item with <strong>bold</strong>",
            "Item with <em>italic</em>"
          ])
        end
      end
    end

    context "with blockquotes" do
      let(:html) { "<blockquote>This is a quote</blockquote>" }

      it "converts to EditorJS quote block" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: "quote",
          data: {
            text: "This is a quote",
            caption: "",
            alignment: "left"
          }
        )
      end
    end

    context "with code blocks" do
      let(:html) { "<pre><code>const x = 42;</code></pre>" }

      it "converts to EditorJS code block" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: "code",
          data: {
            code: "const x = 42;"
          }
        )
      end

      context "without code tag" do
        let(:html) { "<pre>function test() { }</pre>" }

        it "still converts to code block" do
          blocks = subject[:blocks]

          expect(blocks[0][:type]).to eq("code")
          expect(blocks[0][:data][:code]).to eq("function test() { }")
        end
      end
    end

    context "with tables" do
      let(:html) do
        <<~HTML
          <table>
            <thead>
              <tr><th>Header 1</th><th>Header 2</th></tr>
            </thead>
            <tbody>
              <tr><td>Cell 1</td><td>Cell 2</td></tr>
              <tr><td>Cell 3</td><td>Cell 4</td></tr>
            </tbody>
          </table>
        HTML
      end

      it "converts to EditorJS table block" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0][:type]).to eq("table")
        expect(blocks[0][:data][:withHeadings]).to be true
        expect(blocks[0][:data][:content]).to eq([
          ["Header 1", "Header 2"],
          ["Cell 1", "Cell 2"],
          ["Cell 3", "Cell 4"]
        ])
      end

      context "without thead" do
        let(:html) do
          <<~HTML
            <table>
              <tr><td>Cell 1</td><td>Cell 2</td></tr>
              <tr><td>Cell 3</td><td>Cell 4</td></tr>
            </table>
          HTML
        end

        it "converts with withHeadings as false" do
          blocks = subject[:blocks]

          expect(blocks[0][:data][:withHeadings]).to be false
        end
      end
    end

    context "with horizontal rules" do
      let(:html) { "<p>Before</p><hr><p>After</p>" }

      it "converts to EditorJS delimiter block" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(3)
        expect(blocks[1]).to include(
          type: "delimiter",
          data: {}
        )
      end
    end

    context "with plain text nodes" do
      let(:html) { "Just plain text" }

      it "wraps in paragraph block" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: "paragraph",
          data: {
            text: "Just plain text"
          }
        )
      end
    end

    context "with empty paragraphs" do
      let(:html) { "<p></p><p>Content</p><p>   </p>" }

      it "filters out empty paragraphs" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0][:data][:text]).to eq("Content")
      end
    end

    context "with mixed content" do
      let(:html) do
        <<~HTML
          <h1>Article Title</h1>
          <p>Introduction paragraph with <strong>bold</strong> text.</p>
          <h2>Section 1</h2>
          <ul>
            <li>Point 1</li>
            <li>Point 2</li>
          </ul>
          <blockquote>A famous quote</blockquote>
          <pre><code>const code = true;</code></pre>
        HTML
      end

      it "converts all elements correctly" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(6)
        expect(blocks[0][:type]).to eq("header")
        expect(blocks[1][:type]).to eq("paragraph")
        expect(blocks[2][:type]).to eq("header")
        expect(blocks[3][:type]).to eq("list")
        expect(blocks[4][:type]).to eq("quote")
        expect(blocks[5][:type]).to eq("code")
      end
    end

    context "with malformed HTML" do
      let(:html) { "<p>Unclosed paragraph<div>Inside div</div>" }

      it "handles gracefully" do
        expect { subject }.not_to raise_error
        expect(subject[:blocks]).to be_an(Array)
      end
    end

    context "with special characters" do
      let(:html) { '<p>&lt;script&gt;alert("xss")&lt;/script&gt;</p>' }

      it "preserves HTML entities" do
        blocks = subject[:blocks]

        expect(blocks[0][:data][:text]).to include("&lt;script&gt;")
      end
    end

    context "with whitespace" do
      let(:html) { "  \n\n  <p>Content</p>  \n\n  " }

      it "ignores surrounding whitespace" do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0][:type]).to eq("paragraph")
      end
    end
  end
end
