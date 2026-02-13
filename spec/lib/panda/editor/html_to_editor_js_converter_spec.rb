# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Editor::HtmlToEditorJsConverter do
  describe ".convert" do
    it "converts HTML to EditorJS format" do
      html = "<h1>Test</h1>"
      result = described_class.convert(html)

      expect(result).to be_a(Hash)
      expect(result[:blocks]).to be_an(Array)
      expect(result[:version]).to eq("2.28.2")
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

          expect(blocks[0][:data][:text]).to eq("Text with <b>bold</b> and <i>italic</i>")
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
            "Item with <b>bold</b>",
            "Item with <i>italic</i>"
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

      it "decodes HTML entities from text nodes" do
        blocks = subject[:blocks]

        expect(blocks[0][:data][:text]).to include("<script>")
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

    context "with footnotes" do
      context "single footnote" do
        let(:html) do
          <<~HTML
            <p>Text with a claim<sup id="fnref1"><a href="#fn1">1</a></sup>.</p>
            <div class="footnotes"><hr><ol>
              <li id="fn1"><p>Citation here.&nbsp;<a href="#fnref1">&#8617;</a></p></li>
            </ol></div>
          HTML
        end

        it "extracts footnote into paragraph data" do
          blocks = subject[:blocks]

          expect(blocks.length).to eq(1)
          expect(blocks[0][:type]).to eq("paragraph")
          expect(blocks[0][:data][:text]).to eq("Text with a claim.")
          expect(blocks[0][:data][:footnotes]).to eq([
            {id: "fn-1", content: "Citation here.", position: 17}
          ])
        end
      end

      context "multiple footnotes" do
        let(:html) do
          <<~HTML
            <p>First claim<sup id="fnref1"><a href="#fn1">1</a></sup> and second<sup id="fnref2"><a href="#fn2">2</a></sup>.</p>
            <div class="footnotes"><hr><ol>
              <li id="fn1"><p>First citation.&nbsp;<a href="#fnref1">&#8617;</a></p></li>
              <li id="fn2"><p>Second citation.&nbsp;<a href="#fnref2">&#8617;</a></p></li>
            </ol></div>
          HTML
        end

        it "extracts all footnotes with correct positions" do
          blocks = subject[:blocks]

          expect(blocks.length).to eq(1)
          expect(blocks[0][:data][:text]).to eq("First claim and second.")
          expect(blocks[0][:data][:footnotes].length).to eq(2)
          expect(blocks[0][:data][:footnotes][0]).to include(id: "fn-1", content: "First citation.")
          expect(blocks[0][:data][:footnotes][1]).to include(id: "fn-2", content: "Second citation.")
          expect(blocks[0][:data][:footnotes][0][:position]).to be < blocks[0][:data][:footnotes][1][:position]
        end
      end

      context "footnote with missing definition" do
        let(:html) do
          <<~HTML
            <p>Text with ref<sup id="fnref99"><a href="#fn99">99</a></sup>.</p>
            <div class="footnotes"><hr><ol></ol></div>
          HTML
        end

        it "strips the sup but does not add footnote entry" do
          blocks = subject[:blocks]

          expect(blocks.length).to eq(1)
          expect(blocks[0][:data][:text]).to eq("Text with ref.")
          expect(blocks[0][:data]).not_to have_key(:footnotes)
        end
      end

      context "HTML without footnotes" do
        let(:html) { "<p>Normal paragraph</p>" }

        it "does not add footnotes key" do
          blocks = subject[:blocks]

          expect(blocks[0][:data]).not_to have_key(:footnotes)
        end
      end

      context "footnotes div is removed from output" do
        let(:html) do
          <<~HTML
            <p>Text<sup id="fnref1"><a href="#fn1">1</a></sup></p>
            <div class="footnotes"><hr><ol>
              <li id="fn1"><p>Note.&nbsp;<a href="#fnref1">&#8617;</a></p></li>
            </ol></div>
          HTML
        end

        it "does not create a block from the footnotes div" do
          blocks = subject[:blocks]

          expect(blocks.length).to eq(1)
          expect(blocks.none? { |b| b[:data][:text]&.include?("Note.") && b[:type] == "paragraph" && !b[:data].key?(:footnotes) }).to be true
        end
      end
    end

    context "with custom converters" do
      let(:custom_converter) do
        converter = Class.new do
          def self.convert(node)
            return nil unless node.element? && node.name == "blockquote"

            text = node.text.strip
            return nil unless text.start_with?("[CUSTOM]")

            {
              type: "custom_block",
              data: {content: text.sub("[CUSTOM]", "").strip}
            }
          end
        end
        converter
      end

      # Custom converter that preserves inner HTML (like CalloutConverter does)
      let(:html_custom_converter) do
        Class.new do
          def self.convert(node)
            return nil unless node.element? && node.name == "blockquote"

            first_p = node.at_css("p")
            return nil unless first_p&.inner_html&.strip&.start_with?("[!CALLOUT]")

            content = first_p.inner_html.strip.sub("[!CALLOUT]", "").sub(/\A\s*<br\s*\/?>\s*/, "").strip
            {"type" => "callout", "data" => {"type" => "evidence", "content" => content}}
          end
        end
      end

      context "when a custom converter matches" do
        let(:html) { "<blockquote>[CUSTOM] Special content</blockquote>" }

        it "uses the custom converter" do
          result = described_class.convert(html, custom_converters: {"custom" => custom_converter})
          blocks = result[:blocks]

          expect(blocks.length).to eq(1)
          expect(blocks[0][:type]).to eq("custom_block")
          expect(blocks[0][:data][:content]).to eq("Special content")
        end
      end

      context "when no custom converter matches" do
        let(:html) { "<blockquote>Regular quote</blockquote>" }

        it "falls back to default handling" do
          result = described_class.convert(html, custom_converters: {"custom" => custom_converter})
          blocks = result[:blocks]

          expect(blocks.length).to eq(1)
          expect(blocks[0][:type]).to eq("quote")
        end
      end

      context "with no custom converters" do
        let(:html) { "<blockquote>[CUSTOM] Content</blockquote>" }

        it "processes normally" do
          result = described_class.convert(html)
          blocks = result[:blocks]

          expect(blocks[0][:type]).to eq("quote")
        end
      end

      context "with footnotes inside custom block content" do
        let(:html) do
          <<~HTML
            <blockquote><p>[!CALLOUT]<br>Studies show this is true<sup id="fnref1"><a href="#fn1">1</a></sup> and also this<sup id="fnref2"><a href="#fn2">2</a></sup>.</p></blockquote>
            <div class="footnotes"><hr><ol>
              <li id="fn1"><p>First citation.&nbsp;<a href="#fnref1">&#8617;</a></p></li>
              <li id="fn2"><p>Second citation.&nbsp;<a href="#fnref2">&#8617;</a></p></li>
            </ol></div>
          HTML
        end

        it "extracts footnotes into the custom block data" do
          result = described_class.convert(html, custom_converters: {"callout" => html_custom_converter})
          blocks = result[:blocks]

          expect(blocks.length).to eq(1)
          block = blocks[0]
          expect(block["type"]).to eq("callout")
          expect(block["data"]["footnotes"]).to be_an(Array)
          expect(block["data"]["footnotes"].length).to eq(2)
          expect(block["data"]["footnotes"][0]).to eq({"id" => "fn-1", "content" => "First citation."})
          expect(block["data"]["footnotes"][1]).to eq({"id" => "fn-2", "content" => "Second citation."})
        end

        it "replaces raw <sup> tags with placeholder tokens" do
          result = described_class.convert(html, custom_converters: {"callout" => html_custom_converter})
          content = result[:blocks][0]["data"]["content"]

          expect(content).to include("{{FOOTNOTE:fn-1}}")
          expect(content).to include("{{FOOTNOTE:fn-2}}")
          expect(content).not_to include("<sup")
          expect(content).not_to include("fnref")
        end
      end

      context "with footnotes in both custom block and paragraph" do
        let(:html) do
          <<~HTML
            <blockquote><p>[!CALLOUT]<br>Callout claim<sup id="fnref1"><a href="#fn1">1</a></sup>.</p></blockquote>
            <p>Paragraph claim<sup id="fnref2"><a href="#fn2">2</a></sup>.</p>
            <div class="footnotes"><hr><ol>
              <li id="fn1"><p>Callout citation.&nbsp;<a href="#fnref1">&#8617;</a></p></li>
              <li id="fn2"><p>Paragraph citation.&nbsp;<a href="#fnref2">&#8617;</a></p></li>
            </ol></div>
          HTML
        end

        it "extracts footnotes from both block types" do
          result = described_class.convert(html, custom_converters: {"callout" => html_custom_converter})
          blocks = result[:blocks]

          expect(blocks.length).to eq(2)
          expect(blocks[0]["data"]["footnotes"]).to eq([{"id" => "fn-1", "content" => "Callout citation."}])
          expect(blocks[1][:data][:footnotes]).to eq([{id: "fn-2", content: "Paragraph citation.", position: 15}])
        end
      end
    end
  end
end
