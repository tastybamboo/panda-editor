# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Panda::Editor::Blocks::Paragraph, :editorjs do
  include EditorJsHelper

  let(:simple_paragraph) do
    { 'text' => 'Simple paragraph text' }
  end

  let(:formatted_paragraph) do
    { 'text' => 'Text with <b>bold</b> formatting' }
  end

  let(:empty_paragraph) do
    { 'text' => '' }
  end

  it 'renders simple paragraphs correctly' do
    rendered = described_class.new(simple_paragraph).render
    expect(normalize_html(rendered)).to eq(normalize_html('<p>Simple paragraph text</p>'))
  end

  it 'preserves allowed HTML formatting' do
    rendered = described_class.new(formatted_paragraph).render
    expect(normalize_html(rendered)).to eq(normalize_html('<p>Text with <b>bold</b> formatting</p>'))
  end

  it 'renders nothing for empty paragraphs' do
    rendered = described_class.new(empty_paragraph).render
    expect(rendered).to eq('')
  end

  describe 'footnotes' do
    let(:footnote_registry) { Panda::Editor::FootnoteRegistry.new }
    let(:options) { { footnote_registry: footnote_registry } }

    let(:paragraph_with_footnote) do
      {
        'text' => 'People with ADHD are 25x more likely to self-harm',
        'footnotes' => [
          {
            'id' => 'fn-uuid-1',
            'content' => 'Study reference needed for ADHD self-harm statistic.',
            'position' => 32  # After "more likely to self-harm"
          }
        ]
      }
    end

    let(:paragraph_with_multiple_footnotes) do
      {
        'text' => 'Text with first footnote and second footnote here',
        'footnotes' => [
          {
            'id' => 'fn-uuid-1',
            'content' => 'First footnote content',
            'position' => 24  # After "first footnote"
          },
          {
            'id' => 'fn-uuid-2',
            'content' => 'Second footnote content',
            'position' => 45  # After "second footnote"
          }
        ]
      }
    end

    it 'injects footnote markers at correct position' do
      rendered = described_class.new(paragraph_with_footnote, options).render
      expect(rendered).to include('<sup id="fnref:1"')
      expect(rendered).to include('class="footnote-ref"')
      expect(rendered).to include('<a href="#fn:1" class="footnote">1</a>')
    end

    it 'registers footnotes with the footnote registry' do
      described_class.new(paragraph_with_footnote, options).render
      expect(footnote_registry.footnotes.length).to eq(1)
      expect(footnote_registry.footnotes.first[:id]).to eq('fn-uuid-1')
      expect(footnote_registry.footnotes.first[:content]).to eq('Study reference needed for ADHD self-harm statistic.')
    end

    it 'handles multiple footnotes in correct order' do
      rendered = described_class.new(paragraph_with_multiple_footnotes, options).render
      expect(rendered).to include('fnref:1')
      expect(rendered).to include('fnref:2')
      expect(footnote_registry.footnotes.length).to eq(2)
    end

    it 'returns same footnote number for duplicate IDs' do
      # First paragraph with footnote
      described_class.new(paragraph_with_footnote, options).render

      # Second paragraph with same footnote ID
      second_paragraph = {
        'text' => 'Another sentence with same source',
        'footnotes' => [
          {
            'id' => 'fn-uuid-1',
            'content' => 'Study reference needed for ADHD self-harm statistic.',
            'position' => 33
          }
        ]
      }

      rendered = described_class.new(second_paragraph, options).render

      # Should still be footnote 1, not 2
      expect(rendered).to include('<a href="#fn:1" class="footnote">1</a>')
      expect(footnote_registry.footnotes.length).to eq(1)
    end

    it 'works without footnotes' do
      rendered = described_class.new(simple_paragraph, options).render
      expect(normalize_html(rendered)).to eq(normalize_html('<p>Simple paragraph text</p>'))
      expect(footnote_registry.footnotes).to be_empty
    end

    it 'includes tooltip content in data attribute' do
      rendered = described_class.new(paragraph_with_footnote, options).render
      expect(rendered).to include('data-footnote-content=')
      expect(rendered).to include('Study reference needed for ADHD self-harm statistic.')
    end

    it 'includes tooltip content in title attribute for native browser tooltip' do
      rendered = described_class.new(paragraph_with_footnote, options).render
      expect(rendered).to include('title=')
      expect(rendered).to include('Study reference needed for ADHD self-harm statistic.')
    end

    it 'escapes HTML in tooltip attributes' do
      paragraph_with_html_content = {
        'text' => 'Testing HTML escaping',
        'footnotes' => [
          {
            'id' => 'fn-html-test',
            'content' => '<strong>Bold</strong> & "quoted" content',
            'position' => 7  # After "Testing"
          }
        ]
      }
      rendered = described_class.new(paragraph_with_html_content, options).render
      # Verify that HTML is properly escaped in attributes to prevent XSS
      expect(rendered).to be_present
      expect(rendered).to include('data-footnote-content=')
      # HTML should be escaped for safety (< becomes &lt;, etc.)
      expect(rendered).to match(/data-footnote-content=["'][^"']*&lt;strong&gt;/)
    end
  end
end
