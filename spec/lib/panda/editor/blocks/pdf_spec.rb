# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Editor::Blocks::Pdf, :editorjs do
  include EditorJsHelper

  let(:signed_id) { "eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWt4In19--abc123" }

  let(:pdf_data) do
    {
      "file" => {
        "url" => "/rails/active_storage/blobs/redirect/#{signed_id}/document.pdf",
        "name" => "document.pdf",
        "size" => 102_400,
        "extension" => "pdf",
        "signed_id" => signed_id
      },
      "title" => "document.pdf"
    }
  end

  it "renders a PDF viewer container with correct data attribute" do
    rendered = described_class.new(pdf_data).render
    expect(rendered).to include('class="panda-pdf-viewer"')
    expect(rendered).to include("data-pdf-url-endpoint=\"/panda/editor/pdf_url/#{ERB::Util.url_encode(signed_id)}\"")
  end

  it "renders canvas element" do
    rendered = described_class.new(pdf_data).render
    expect(rendered).to include('class="panda-pdf-viewer__canvas"')
  end

  it "renders page navigation controls" do
    rendered = described_class.new(pdf_data).render
    expect(rendered).to include('class="panda-pdf-viewer__prev"')
    expect(rendered).to include('class="panda-pdf-viewer__next"')
    expect(rendered).to include('class="panda-pdf-viewer__page-info"')
  end

  it "renders noscript fallback" do
    rendered = described_class.new(pdf_data).render
    expect(rendered).to include("<noscript>")
    expect(rendered).to include("PDF viewer requires JavaScript")
  end

  it "includes aria-label with sanitized filename" do
    rendered = described_class.new(pdf_data).render
    expect(rendered).to include('aria-label="document.pdf"')
  end

  it "includes PDF.js script and CSS tags" do
    rendered = described_class.new(pdf_data).render
    expect(rendered).to include("/panda/editor/pdf_viewer.js")
    expect(rendered).to include("/panda/editor/pdf_viewer.css")
  end

  it "returns empty string when signed_id is missing" do
    data = {"file" => {"url" => "/some/url", "name" => "test.pdf"}}
    rendered = described_class.new(data).render
    expect(rendered).to eq("")
  end

  it "returns empty string when file data is missing" do
    rendered = described_class.new({}).render
    expect(rendered).to eq("")
  end

  it "returns empty string when signed_id is blank" do
    data = {"file" => {"signed_id" => "", "name" => "test.pdf"}}
    rendered = described_class.new(data).render
    expect(rendered).to eq("")
  end

  it "sanitizes filename in aria-label" do
    data = pdf_data.merge("file" => pdf_data["file"].merge("name" => '<script>alert("xss")</script>'))
    rendered = described_class.new(data).render
    expect(rendered).not_to include("<script>")
  end

  context "asset tag deduplication" do
    it "includes asset tags only once across multiple PDF blocks" do
      options = {}
      rendered1 = described_class.new(pdf_data, options).render
      rendered2 = described_class.new(pdf_data, options).render

      expect(rendered1).to include("pdf_viewer.js")
      expect(rendered2).not_to include("pdf_viewer.js")
    end
  end
end
