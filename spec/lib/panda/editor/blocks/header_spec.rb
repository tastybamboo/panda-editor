# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Editor::Blocks::Header, :editorjs do
  include EditorJsHelper

  let(:h2_header) do
    {"text" => "Main Header", "level" => 2}
  end

  let(:h3_header) do
    {"text" => "Sub Header", "level" => 3}
  end

  it "renders h2 headers with slugified id" do
    rendered = described_class.new(h2_header).render
    expect(normalize_html(rendered)).to eq(normalize_html('<h2 id="main-header">Main Header</h2>'))
  end

  it "renders h3 headers with slugified id" do
    rendered = described_class.new(h3_header).render
    expect(normalize_html(rendered)).to eq(normalize_html('<h3 id="sub-header">Sub Header</h3>'))
  end

  it "strips HTML tags from slug" do
    data = {"text" => "Header with <b>bold</b> text", "level" => 2}
    rendered = described_class.new(data).render
    expect(rendered).to include('id="header-with-bold-text"')
  end

  it "removes special characters from slug" do
    data = {"text" => "What's the benefit?", "level" => 2}
    rendered = described_class.new(data).render
    expect(rendered).to include('id="whats-the-benefit"')
  end

  it "collapses multiple spaces and hyphens" do
    data = {"text" => "Bronze Partner — £1,000/year", "level" => 3}
    rendered = described_class.new(data).render
    expect(rendered).to include('id="bronze-partner-1000year"')
  end

  it "handles leading and trailing whitespace" do
    data = {"text" => "  Padded Header  ", "level" => 2}
    rendered = described_class.new(data).render
    expect(rendered).to include('id="padded-header"')
  end

  it "defaults to level 2 when level is not specified" do
    data = {"text" => "No Level"}
    rendered = described_class.new(data).render
    expect(rendered).to include("<h2")
  end

  context "with slug registry for deduplication" do
    let(:registry) { Hash.new(0) }
    let(:options) { {slug_registry: registry} }

    it "appends suffix to duplicate headings" do
      data = {"text" => "Amount", "level" => 2}
      first = described_class.new(data, options).render
      second = described_class.new(data, options).render
      third = described_class.new(data, options).render

      expect(first).to include('id="amount"')
      expect(second).to include('id="amount-2"')
      expect(third).to include('id="amount-3"')
    end

    it "tracks different headings independently" do
      described_class.new({"text" => "One", "level" => 2}, options).render
      described_class.new({"text" => "Two", "level" => 2}, options).render
      second_one = described_class.new({"text" => "One", "level" => 2}, options).render

      expect(second_one).to include('id="one-2"')
    end
  end
end
