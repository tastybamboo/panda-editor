# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Editor::Blocks::Image, :editorjs do
  include EditorJsHelper

  context "with legacy simple-image format (url at top level)" do
    let(:image_with_caption) do
      {
        "url" => "/path/to/image.jpg",
        "caption" => "Beautiful sunset",
        "withBorder" => true,
        "withBackground" => true,
        "stretched" => true
      }
    end

    let(:simple_image) do
      {
        "url" => "/path/to/image.jpg"
      }
    end

    it "renders image with all options correctly" do
      rendered = described_class.new(image_with_caption).render
      expect(normalize_html(rendered)).to eq(normalize_html(
                                               '<figure class="prose border bg-gray-100 w-full">' \
                                                 '<img src="/path/to/image.jpg" alt="Beautiful sunset" />' \
                                                 "<figcaption>Beautiful sunset</figcaption>" \
                                               "</figure>"
                                             ))
    end

    it "renders simple image correctly" do
      rendered = described_class.new(simple_image).render
      expect(normalize_html(rendered)).to eq(normalize_html(
                                               '<figure class="prose">' \
                                                 '<img src="/path/to/image.jpg" alt="" />' \
                                               "</figure>"
                                             ))
    end
  end

  context "with @editorjs/image format (url nested under file)" do
    let(:image_with_file_url) do
      {
        "file" => {"url" => "/uploads/photo.png"},
        "caption" => "A photo",
        "withBorder" => false,
        "withBackground" => false,
        "stretched" => false
      }
    end

    let(:image_with_file_url_and_options) do
      {
        "file" => {"url" => "/uploads/photo.png"},
        "caption" => "Styled photo",
        "withBorder" => true,
        "withBackground" => true,
        "stretched" => true
      }
    end

    let(:image_with_file_url_no_caption) do
      {
        "file" => {"url" => "/uploads/photo.png"}
      }
    end

    it "renders image from file.url" do
      rendered = described_class.new(image_with_file_url).render
      expect(normalize_html(rendered)).to eq(normalize_html(
                                               '<figure class="prose">' \
                                                 '<img src="/uploads/photo.png" alt="A photo" />' \
                                                 "<figcaption>A photo</figcaption>" \
                                               "</figure>"
                                             ))
    end

    it "renders image from file.url with all options" do
      rendered = described_class.new(image_with_file_url_and_options).render
      expect(normalize_html(rendered)).to eq(normalize_html(
                                               '<figure class="prose border bg-gray-100 w-full">' \
                                                 '<img src="/uploads/photo.png" alt="Styled photo" />' \
                                                 "<figcaption>Styled photo</figcaption>" \
                                               "</figure>"
                                             ))
    end

    it "renders image from file.url without caption" do
      rendered = described_class.new(image_with_file_url_no_caption).render
      expect(normalize_html(rendered)).to eq(normalize_html(
                                               '<figure class="prose">' \
                                                 '<img src="/uploads/photo.png" alt="" />' \
                                               "</figure>"
                                             ))
    end
  end
end
