# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Panda::Editor::MarkdownToEditorJsConverter do
  describe '.convert' do
    it 'converts Markdown to EditorJS format' do
      markdown = '# Test'
      result = described_class.convert(markdown)

      expect(result).to be_a(Hash)
      expect(result[:blocks]).to be_an(Array)
      expect(result[:version]).to eq("2.28.0")
    end

    it 'handles empty markdown' do
      result = described_class.convert('')

      expect(result[:blocks]).to be_empty
    end
  end

  describe '#convert' do
    subject { described_class.new(markdown).convert }

    context 'with headers' do
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

      it 'converts headers to EditorJS header blocks' do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(6)
        (1..6).each do |level|
          expect(blocks[level - 1]).to include(
            type: 'header',
            data: include(level: level)
          )
        end
      end
    end

    context 'with paragraphs' do
      let(:markdown) do
        <<~MD
          First paragraph

          Second paragraph
        MD
      end

      it 'converts paragraphs to EditorJS paragraph blocks' do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(2)
        expect(blocks[0]).to include(
          type: 'paragraph',
          data: include(text: /First paragraph/)
        )
        expect(blocks[1]).to include(
          type: 'paragraph',
          data: include(text: /Second paragraph/)
        )
      end
    end

    context 'with inline formatting' do
      let(:markdown) { 'Text with **bold** and *italic* and ~~strikethrough~~' }

      it 'converts to HTML tags in EditorJS' do
        blocks = subject[:blocks]

        expect(blocks[0][:data][:text]).to include('<strong>bold</strong>')
        expect(blocks[0][:data][:text]).to include('<em>italic</em>')
        expect(blocks[0][:data][:text]).to include('<del>strikethrough</del>')
      end
    end

    context 'with links' do
      let(:markdown) { 'Check out [this link](https://example.com)' }

      it 'converts to HTML anchor tags' do
        blocks = subject[:blocks]

        expect(blocks[0][:data][:text]).to include('<a')
        expect(blocks[0][:data][:text]).to include('href="https://example.com"')
        expect(blocks[0][:data][:text]).to include('this link')
      end

      it 'adds security attributes to links' do
        blocks = subject[:blocks]

        expect(blocks[0][:data][:text]).to include('rel="noopener noreferrer"')
      end
    end

    context 'with autolinks' do
      let(:markdown) { 'Visit https://example.com for more info' }

      it 'automatically converts URLs to links' do
        blocks = subject[:blocks]

        expect(blocks[0][:data][:text]).to include('<a')
        expect(blocks[0][:data][:text]).to include('href="https://example.com"')
      end
    end

    context 'with unordered lists' do
      let(:markdown) do
        <<~MD
          - Item 1
          - Item 2
          - Item 3
        MD
      end

      it 'converts to EditorJS list block' do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: 'list',
          data: include(
            style: 'unordered',
            items: ['Item 1', 'Item 2', 'Item 3']
          )
        )
      end
    end

    context 'with ordered lists' do
      let(:markdown) do
        <<~MD
          1. First item
          2. Second item
          3. Third item
        MD
      end

      it 'converts to EditorJS ordered list block' do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: 'list',
          data: include(
            style: 'ordered',
            items: ['First item', 'Second item', 'Third item']
          )
        )
      end
    end

    context 'with blockquotes' do
      let(:markdown) { '> This is a quote' }

      it 'converts to EditorJS quote block' do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: 'quote',
          data: include(
            text: /This is a quote/
          )
        )
      end
    end

    context 'with fenced code blocks' do
      let(:markdown) do
        <<~MD
          ```javascript
          const x = 42;
          console.log(x);
          ```
        MD
      end

      it 'converts to EditorJS code block' do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: 'code',
          data: include(
            code: /const x = 42/
          )
        )
      end
    end

    context 'with indented code blocks' do
      let(:markdown) do
        <<~MD
          Regular text

              indented code
              more code
        MD
      end

      it 'converts to EditorJS code block' do
        blocks = subject[:blocks]

        expect(blocks).to satisfy { |b| b.any? { |block| block[:type] == 'code' } }
      end
    end

    context 'with tables' do
      let(:markdown) do
        <<~MD
          | Header 1 | Header 2 |
          |----------|----------|
          | Cell 1   | Cell 2   |
          | Cell 3   | Cell 4   |
        MD
      end

      it 'converts to EditorJS table block' do
        blocks = subject[:blocks]

        expect(blocks.length).to eq(1)
        expect(blocks[0]).to include(
          type: 'table',
          data: include(
            withHeadings: true,
            content: be_an(Array)
          )
        )
      end
    end

    context 'with horizontal rules' do
      let(:markdown) do
        <<~MD
          Before

          ---

          After
        MD
      end

      it 'converts to EditorJS delimiter block' do
        blocks = subject[:blocks]

        expect(blocks).to satisfy { |b|
          b.any? { |block| block[:type] == 'delimiter' }
        }
      end
    end

    context 'with superscript' do
      let(:markdown) { 'E = mc^2' }

      it 'converts to superscript HTML' do
        blocks = subject[:blocks]

        expect(blocks[0][:data][:text]).to include('<sup>2</sup>')
      end
    end

    context 'with footnotes' do
      let(:markdown) do
        <<~MD
          Text with a footnote[^1].

          [^1]: This is the footnote.
        MD
      end

      it 'processes footnotes' do
        # Redcarpet processes footnotes to HTML
        expect { subject }.not_to raise_error
        expect(subject[:blocks]).to be_an(Array)
      end
    end

    context 'with mixed content' do
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

      it 'converts all markdown elements correctly' do
        blocks = subject[:blocks]

        expect(blocks).to satisfy { |b| b.any? { |block| block[:type] == 'header' } }
        expect(blocks).to satisfy { |b| b.any? { |block| block[:type] == 'paragraph' } }
        expect(blocks).to satisfy { |b| b.any? { |block| block[:type] == 'list' } }
        expect(blocks).to satisfy { |b| b.any? { |block| block[:type] == 'quote' } }
        expect(blocks).to satisfy { |b| b.any? { |block| block[:type] == 'code' } }
      end
    end

    context 'with edge cases' do
      context 'empty string' do
        let(:markdown) { '' }

        it 'returns empty blocks' do
          expect(subject[:blocks]).to be_empty
        end
      end

      context 'only whitespace' do
        let(:markdown) { "  \n\n  \n  " }

        it 'returns empty blocks' do
          expect(subject[:blocks]).to be_empty
        end
      end

      context 'special characters' do
        let(:markdown) { 'Text with & < > " characters' }

        it 'escapes HTML entities' do
          blocks = subject[:blocks]

          # Markdown processors escape these
          expect(blocks[0][:data][:text]).not_to include('<')
          expect(blocks[0][:data][:text]).not_to include('>')
        end
      end

      context 'hard line breaks' do
        let(:markdown) do
          "Line one  \nLine two"
        end

        it 'preserves hard line breaks' do
          blocks = subject[:blocks]

          expect(blocks[0][:data][:text]).to include('<br')
        end
      end

      context 'with no_intra_emphasis' do
        let(:markdown) { 'some_variable_name' }

        it 'does not treat underscores in words as emphasis' do
          blocks = subject[:blocks]

          expect(blocks[0][:data][:text]).to eq('some_variable_name')
        end
      end
    end

    context 'integration with HtmlToEditorJsConverter' do
      let(:markdown) { '# Test Header' }

      it 'uses HtmlToEditorJsConverter internally' do
        # Verify the conversion pipeline works end-to-end
        expect(Panda::Editor::HtmlToEditorJsConverter).to receive(:convert).and_call_original

        subject
      end
    end
  end

  describe 'error handling' do
    context 'with nil input' do
      it 'raises TypeError for nil input' do
        expect { described_class.new(nil).convert }.to raise_error(TypeError)
      end
    end

    context 'with invalid markdown' do
      let(:markdown) { '<script>alert("xss")</script>' }

      it 'handles potentially malicious content' do
        expect { described_class.new(markdown).convert }.not_to raise_error
      end
    end
  end
end
