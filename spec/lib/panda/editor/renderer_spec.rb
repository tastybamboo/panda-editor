# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Editor::Renderer, :editorjs do
  include EditorJsHelper

  let(:complex_content) do
    {
      "time" => 1_730_070_062_274,
      "blocks" => [
        {
          "id" => "EBYBrK_4CA",
          "data" => {"text" => "Test"},
          "type" => "paragraph"
        },
        {
          "id" => "p04DjXuFCZ",
          "data" => {"text" => "<b>test</b>"},
          "type" => "paragraph"
        },
        {
          "id" => "R2lt9xirkd",
          "data" => {
            "items" => [
              {
                "content" => "Main list item",
                "items" => [
                  "Nested item 1",
                  "Nested item 2"
                ]
              },
              {"content" => "Second main item"}
            ],
            "style" => "unordered"
          },
          "type" => "list"
        },
        {
          "id" => "KwNCPYju8h",
          "data" => {"text" => "<i>Styled</i> Heading", "level" => 2},
          "type" => "header"
        },
        {
          "id" => "quote1",
          "data" => {
            "text" => "Quote with <u>underline</u>",
            "caption" => "Caption with <a href='#'>link</a>",
            "alignment" => "center"
          },
          "type" => "quote"
        }
      ]
    }
  end

  let(:content_with_trailing_empty) do
    {
      "blocks" => [
        {
          "type" => "paragraph",
          "data" => {"text" => "Real content"}
        },
        {
          "type" => "paragraph",
          "data" => {"text" => ""}
        }
      ]
    }
  end

  it "renders complex content with all edge cases" do # rubocop:disable RSpec/ExampleLength
    Rails.cache.clear
    rendered = described_class.new(complex_content).render
    normalized_rendered = normalize_html(rendered)

    # Test each component separately
    expect(normalized_rendered).to include("<p>Test</p>")
    expect(normalized_rendered).to include("<p><b>test</b></p>")
    expect(normalized_rendered).to include(
      "<ul>" \
        "<li>Main list item<ul>" \
          "<li>Nested item 1</li>" \
          "<li>Nested item 2</li>" \
        "</ul></li>" \
        "<li>Second main item</li>" \
      "</ul>"
    )
    expect(normalized_rendered).to include('<h2 id="styled-heading"><i>Styled</i> Heading</h2>')
    expect(normalized_rendered).to include(
      '<figure class="text-center">' \
        "<blockquote><p>Quote with <u>underline</u></p></blockquote>" \
        '<figcaption>Caption with <a href="#">link</a></figcaption>' \
      "</figure>"
    )
  end

  it "handles empty or nil content gracefully" do
    expect(described_class.new(nil).render).to eq("")
    expect(described_class.new({}).render).to eq("")
    expect(described_class.new({"blocks" => []}).render).to eq("")
  end

  it "removes trailing empty paragraphs" do
    rendered = described_class.new(content_with_trailing_empty).render
    expect(normalize_html(rendered)).to eq(normalize_html("<p>Real content</p>"))
  end

  it "removes consecutive empty paragraphs" do
    content_with_empty_paragraphs = {
      "blocks" => [
        {
          "type" => "paragraph",
          "data" => {"text" => "First content"}
        },
        {
          "type" => "paragraph",
          "data" => {"text" => ""}
        },
        {
          "type" => "paragraph",
          "data" => {"text" => ""}
        },
        {
          "type" => "paragraph",
          "data" => {"text" => "Middle content"}
        },
        {
          "type" => "paragraph",
          "data" => {"text" => ""}
        },
        {
          "type" => "paragraph",
          "data" => {"text" => ""}
        }
      ]
    }

    rendered = described_class.new(content_with_empty_paragraphs).render
    expect(normalize_html(rendered)).to eq(
      normalize_html("<p>First content</p><p>Middle content</p>")
    )
  end

  it "supports custom block renderers" do
    custom_renderer = Class.new(Panda::Editor::Blocks::Base) do
      def render
        "<custom>#{data["text"]}</custom>"
      end
    end

    content_with_custom_block = {
      "blocks" => [
        {
          "type" => "custom_block",
          "data" => {"text" => "Custom content"}
        }
      ]
    }

    rendered = described_class.new(
      content_with_custom_block,
      custom_renderers: {"custom_block" => custom_renderer}
    ).render

    expect(normalize_html(rendered)).to eq("<custom>Custom content</custom>")
  end

  it "caches rendered blocks" do
    cache_store = ActiveSupport::Cache::MemoryStore.new

    content_to_cache = {
      "blocks" => [
        {
          "type" => "paragraph",
          "data" => {"text" => "Cached content"}
        }
      ]
    }

    # First render should cache
    rendered_first = described_class.new(content_to_cache, cache_store: cache_store).render
    expect(normalize_html(rendered_first)).to eq("<p>Cached content</p>")

    # Second render should hit cache
    rendered_second = described_class.new(content_to_cache, cache_store: cache_store).render
    expect(normalize_html(rendered_second)).to eq("<p>Cached content</p>")

    expect(cache_store.read("editor_js_block/paragraph/#{Digest::MD5.hexdigest({"text" => "Cached content"}.to_json)}"))
      .to eq("<p>Cached content</p>")
  end

  context "with custom renderers" do
    let(:custom_paragraph) do
      Class.new(Panda::Editor::Blocks::Base) do
        def render
          "<div class='custom-paragraph'>#{data["text"]}</div>"
        end
      end
    end

    let(:custom_header) do
      Class.new(Panda::Editor::Blocks::Base) do
        def render
          "<h#{data["level"]} class='custom-header'>#{data["text"]}</h#{data["level"]}>"
        end
      end
    end

    let(:content_with_multiple_blocks) do
      {
        "blocks" => [
          {
            "type" => "paragraph",
            "data" => {"text" => "Custom paragraph"}
          },
          {
            "type" => "header",
            "data" => {"text" => "Custom header", "level" => 2}
          }
        ]
      }
    end

    it "overrides default renderers with custom ones" do
      rendered = described_class.new(
        content_with_multiple_blocks,
        custom_renderers: {
          "paragraph" => custom_paragraph,
          "header" => custom_header
        }
      ).render

      expect(normalize_html(rendered)).to eq(
        normalize_html(
          "<div class='custom-paragraph'>Custom paragraph</div>" \
          "<h2 class='custom-header'>Custom header</h2>"
        )
      )
    end
  end

  context "with block combinations" do
    before { Rails.cache.clear }

    let(:sample_blocks) do
      [
        {
          "type" => "header",
          "data" => {"text" => "Test Header", "level" => 2}
        },
        {
          "type" => "paragraph",
          "data" => {"text" => "Test content"}
        }
      ]
    end

    let(:renderer) { described_class.new({"blocks" => sample_blocks}) }

    it "renders content sections" do
      rendered = renderer.section(sample_blocks)
      expect(normalize_html(rendered)).to eq(
        normalize_html(
          '<section class="content-section">' \
            '<h2 id="test-header">Test Header</h2>' \
            "<p>Test content</p>" \
          "</section>"
        )
      )
    end

    it "renders articles with optional title" do
      rendered = renderer.article(sample_blocks, title: "Article Title")
      expect(normalize_html(rendered)).to eq(
        normalize_html(
          "<article>" \
            "<h1>Article Title</h1>" \
            '<h2 id="test-header">Test Header</h2>' \
            "<p>Test content</p>" \
          "</article>"
        )
      )
    end

    it "renders articles without title" do
      rendered = renderer.article(sample_blocks)
      expect(normalize_html(rendered)).to eq(
        normalize_html(
          "<article>" \
            '<h2 id="test-header">Test Header</h2>' \
            "<p>Test content</p>" \
          "</article>"
        )
      )
    end
  end

  context "with HTML validation" do
    let(:valid_content) do
      {
        "blocks" => [
          {
            "type" => "quote",
            "data" => {
              "text" => "<p>Valid HTML</p>",
              "caption" => "Valid caption"
            }
          }
        ]
      }
    end

    let(:invalid_content) do
      {
        "blocks" => [
          {
            "type" => "quote",
            "data" => {
              "text" => "<p>Invalid HTML<p>",
              "caption" => "Invalid <div>caption"
            }
          }
        ]
      }
    end

    it "validates HTML structure" do
      valid_rendered = described_class.new(valid_content, validate_html: true).render
      expect(normalize_html(valid_rendered)).to eq(
        normalize_html('<figure class="text-left"><blockquote><p>Valid HTML</p></blockquote><figcaption>Valid caption</figcaption></figure>')
      )

      invalid_rendered = described_class.new(invalid_content, validate_html: true).render
      expect(invalid_rendered).to eq("")
    end
  end

  context "with configurable custom renderers" do
    let(:configurable_renderer) do
      Class.new(Panda::Editor::Blocks::Base) do
        def render
          wrapper_class = options[:wrapper_class] || "default-wrapper"
          "<div class='#{wrapper_class}'>#{data["text"]}</div>"
        end
      end
    end

    let(:content_with_custom_blocks) do
      {
        "blocks" => [
          {
            "type" => "custom_block",
            "data" => {"text" => "First custom block"}
          },
          {
            "type" => "custom_block",
            "data" => {"text" => "Second custom block"}
          }
        ]
      }
    end

    it "renders blocks with custom configuration" do
      rendered = described_class.new(
        content_with_custom_blocks,
        custom_renderers: {"custom_block" => configurable_renderer},
        wrapper_class: "special-wrapper"
      ).render

      expect(normalize_html(rendered)).to eq(
        normalize_html(
          "<div class='special-wrapper'>First custom block</div>" \
          "<div class='special-wrapper'>Second custom block</div>"
        )
      )
    end

    context "with configurable custom renderers" do
      let(:complex_renderer) do
        Class.new(Panda::Editor::Blocks::Base) do
          def render
            styles = build_styles
            content = process_content

            %(<div #{styles}>
              #{content}
              #{render_footer if options.dig(:footer, :enabled)}
            </div>)
          end

          private

          def build_styles
            style_options = options[:styles] || {}
            classes = ["base-block"]
            classes << style_options[:theme] if style_options[:theme]
            classes << "animate" if style_options[:animate]

            data_attrs = style_options[:data]&.map { |k, v| %(data-#{k}="#{v}") }&.join(" ")

            %(class="#{classes.join(" ")}" #{data_attrs})
          end

          def process_content
            content = data["text"]
            transforms = options[:transforms] || []

            transforms.each do |transform|
              case transform
              when "markdown"
                content = markdown_to_html(content)
              when "emoji"
                content = convert_emoji(content)
              when "mentions"
                content = process_mentions(content)
              end
            end

            content
          end

          def render_footer
            footer_config = options[:footer]
            %(<footer class="#{footer_config[:class]}">#{footer_config[:text]}</footer>)
          end

          def markdown_to_html(content)
            content.gsub(/`([^`]+)`/, '<code>\1</code>')
          end

          def convert_emoji(content)
            content.gsub(":smile:", "\u{1F60A}")
          end

          def process_mentions(content)
            content.gsub(/@(\w+)/, '<mention>@\1</mention>')
          end
        end

        it "handles nested configuration options" do
          content = {
            "blocks" => [
              {
                "type" => "complex_block",
                "data" => {"text" => "Hello @user! :smile:"}
              }
            ]
          }

          rendered = described_class.new(
            content,
            custom_renderers: {"complex_block" => complex_renderer},
            styles: {
              theme: "modern",
              animate: true,
              data: {controller: "block", action: "hover->block#highlight"}
            },
            transforms: %w[mentions emoji],
            footer: {
              enabled: true,
              class: "block-footer",
              text: "Last updated today"
            }
          ).render

          expect(normalize_html(rendered)).to include('class="base-block modern animate"')
          expect(rendered).to include('data-controller="block"')
          expect(rendered).to include('data-action="hover->block#highlight"')
          expect(rendered).to include('<footer class="block-footer">Last updated today</footer>')
        end
      end
    end

    context "with middleware and event hooks" do
      let(:advanced_renderer) do
        Class.new(Panda::Editor::Blocks::Base) do
          def render
            content = apply_middleware(data["text"])
            trigger_hooks(:before_render, content)
            html = build_html(content)
            trigger_hooks(:after_render, html)
            html
          end

          private

          def apply_middleware(content)
            return content unless options[:middleware]

            options[:middleware].reduce(content) do |text, middleware|
              case middleware
              when :sanitize
                sanitize(text)
              when :format_code
                format_code_blocks(text)
              when :process_math
                process_math_equations(text)
              else
                text
              end
            end
          end

          def format_code_blocks(text)
            text.gsub(/```(\w+)\n(.*?)```/m, '<pre><code class="\1">\2</code></pre>')
          end

          def process_math_equations(text)
            text.gsub("E = mc^2", "<math>E = mc\u00B2</math>")
          end

          def trigger_hooks(event, content)
            return content unless options[:hooks]&.[](event)

            options[:hooks][event].call(content)
          end

          def build_html(content)
            %(<div class="content">#{content}</div>)
          end
        end
      end
    end
  end

  context "with template inheritance and dynamic components" do
    let(:component_renderer) do
      Class.new(Panda::Editor::Blocks::Base) do
        def render
          layout = select_layout
          components = load_components

          layout.render(
            content: render_components(components),
            metadata: build_metadata
          )
        end

        private

        def select_layout
          layout_name = options.dig(:layout, :type) || "default"
          Layout.new(
            template: layout_name,
            theme: options.dig(:layout, :theme),
            responsive: options.dig(:layout, :responsive)
          )
        end

        def load_components
          (options[:components] || []).map do |component|
            Component.new(
              type: component[:type],
              data: data[component[:data_key]],
              config: component[:config]
            )
          end
        end

        def render_components(components)
          components.map(&:render).join("\n")
        end

        def build_metadata
          {
            author: options[:author],
            published_at: Time.current,
            tags: options[:tags],
            category: options[:category]
          }
        end
      end
    end

    it "renders complex nested components with inherited layouts" do
      content = {
        "blocks" => [
          {
            "type" => "component_block",
            "data" => {
              "header" => "Welcome to our blog",
              "sidebar" => ["Recent Posts", "Categories", "Tags"],
              "main" => "Main content here",
              "footer" => "Copyright 2024"
            }
          }
        ]
      }

      rendered = described_class.new(
        content,
        custom_renderers: {"component_block" => component_renderer},
        layout: {
          type: "blog",
          theme: "modern",
          responsive: true
        },
        components: [
          {type: "header", data_key: "header", config: {sticky: true}},
          {type: "sidebar", data_key: "sidebar", config: {position: "right"}},
          {type: "main", data_key: "main", config: {columns: 2}},
          {type: "footer", data_key: "footer", config: {minimal: true}}
        ],
        author: "John Doe",
        category: "Technology",
        tags: %w[web design ruby]
      ).render

      expect(rendered).to include('class="blog-layout modern"')
      expect(rendered).to include('data-sticky="true"')
      expect(rendered).to include("sidebar-right")
      expect(rendered).to include("two-column-layout")
      expect(rendered).to include("minimal-footer")
    end
  end

  describe "footnotes" do
    let(:content_with_footnotes) do
      {
        "blocks" => [
          {
            "type" => "paragraph",
            "data" => {
              "text" => "People with ADHD are 25x more likely to self-harm",
              "footnotes" => [
                {
                  "id" => "fn-uuid-1",
                  "content" => "Study reference needed for ADHD self-harm statistic.",
                  "position" => 32
                }
              ]
            }
          },
          {
            "type" => "paragraph",
            "data" => {
              "text" => "Suicide is the leading cause of death for adults with autism",
              "footnotes" => [
                {
                  "id" => "fn-uuid-2",
                  "content" => "Study reference needed for autism suicide statistic.",
                  "position" => 45
                }
              ]
            }
          }
        ]
      }
    end

    it "renders footnote markers in paragraphs and exposes footnote data" do
      renderer = described_class.new(content_with_footnotes)
      output = renderer.render

      # Check that footnote markers are in paragraphs (with tooltip support)
      expect(output).to include('<sup id="fnref:1"')
      expect(output).to include('class="footnote-ref"')
      expect(output).to include('<a href="#fn:1" class="footnote">1</a>')
      expect(output).to include('<sup id="fnref:2"')
      expect(output).to include('<a href="#fn:2" class="footnote">2</a>')

      # Sources section is no longer auto-appended to rendered output
      expect(output).not_to include("Sources/References")

      # Footnote data is available via the registry
      footnotes = renderer.footnote_registry.processed_footnotes
      expect(footnotes.length).to eq(2)
      expect(footnotes[0][:number]).to eq(1)
      expect(footnotes[0][:content]).to include("Study reference needed for ADHD self-harm statistic.")
      expect(footnotes[1][:number]).to eq(2)
      expect(footnotes[1][:content]).to include("Study reference needed for autism suicide statistic.")
    end

    it "returns empty processed_footnotes when no footnotes" do
      content_without_footnotes = {
        "blocks" => [
          {
            "type" => "paragraph",
            "data" => {"text" => "Simple paragraph without footnotes"}
          }
        ]
      }

      renderer = described_class.new(content_without_footnotes)
      output = renderer.render

      expect(output).not_to include("Sources/References")
      expect(renderer.footnote_registry.processed_footnotes).to be_empty
    end

    it "handles duplicate footnote IDs correctly" do
      content_with_duplicate_footnotes = {
        "blocks" => [
          {
            "type" => "paragraph",
            "data" => {
              "text" => "First reference to study",
              "footnotes" => [
                {
                  "id" => "fn-uuid-1",
                  "content" => "Important study",
                  "position" => 16
                }
              ]
            }
          },
          {
            "type" => "paragraph",
            "data" => {
              "text" => "Second reference to same study",
              "footnotes" => [
                {
                  "id" => "fn-uuid-1",
                  "content" => "Important study",
                  "position" => 24
                }
              ]
            }
          }
        ]
      }

      renderer = described_class.new(content_with_duplicate_footnotes)
      output = renderer.render

      # Both markers in the text should reference footnote 1
      expect(output.scan("fnref:1").length).to eq(2)

      # Only one entry in processed footnotes (deduplicated)
      footnotes = renderer.footnote_registry.processed_footnotes
      expect(footnotes.length).to eq(1)
      expect(footnotes[0][:content]).to include("Important study")
    end

    describe "autolink_urls option" do
      let(:content_with_url) do
        {
          "blocks" => [
            {
              "type" => "paragraph",
              "data" => {
                "text" => "This is a test",
                "footnotes" => [
                  {
                    "id" => "fn-doi",
                    "content" => "Ward, J.H. & Curran, S. (2021). Self-harm as the first presentation of attention deficit hyperactivity disorder in adolescents. Child & Adolescent Mental Health, 26(4), 303-309. https://doi.org/10.1111/camh.12471",
                    "position" => 14
                  }
                ]
              }
            }
          ]
        }
      end

      it "converts plain URLs to links when autolink_urls is true" do
        renderer = described_class.new(content_with_url, autolink_urls: true)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        expect(footnotes.length).to eq(1)
        expect(footnotes[0][:content]).to include('<a href="https://doi.org/10.1111/camh.12471" target="_blank" rel="noopener noreferrer">https://doi.org/10.1111/camh.12471</a>')
      end

      it "does not convert URLs when autolink_urls is false" do
        renderer = described_class.new(content_with_url, autolink_urls: false)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        expect(footnotes[0][:content]).to include("https://doi.org/10.1111/camh.12471")
        expect(footnotes[0][:content]).not_to match(%r{<a[^>]*href="https://doi\.org/10\.1111/camh\.12471"[^>]*>https://doi\.org/10\.1111/camh\.12471</a>})
      end

      it "does not convert URLs when autolink_urls is not specified" do
        renderer = described_class.new(content_with_url)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        expect(footnotes[0][:content]).to include("https://doi.org/10.1111/camh.12471")
        expect(footnotes[0][:content]).not_to match(%r{<a[^>]*href="https://doi\.org/10\.1111/camh\.12471"[^>]*>https://doi\.org/10\.1111/camh\.12471</a>})
      end

      it "does not double-link URLs that are already in anchor tags" do
        content_with_existing_link = {
          "blocks" => [
            {
              "type" => "paragraph",
              "data" => {
                "text" => "Test",
                "footnotes" => [
                  {
                    "id" => "fn-link",
                    "content" => 'Already linked: <a href="https://example.com">https://example.com</a>',
                    "position" => 4
                  }
                ]
              }
            }
          ]
        }

        renderer = described_class.new(content_with_existing_link, autolink_urls: true)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        expect(footnotes[0][:content].scan(%r{<a[^>]*href="https://example\.com"}).length).to eq(1)
      end

      it "handles multiple URLs in one footnote" do
        content_with_multiple_urls = {
          "blocks" => [
            {
              "type" => "paragraph",
              "data" => {
                "text" => "Test",
                "footnotes" => [
                  {
                    "id" => "fn-multi",
                    "content" => "See https://example.com and https://another.org for more info",
                    "position" => 4
                  }
                ]
              }
            }
          ]
        }

        renderer = described_class.new(content_with_multiple_urls, autolink_urls: true)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        expect(footnotes[0][:content]).to include('<a href="https://example.com" target="_blank" rel="noopener noreferrer">https://example.com</a>')
        expect(footnotes[0][:content]).to include('<a href="https://another.org" target="_blank" rel="noopener noreferrer">https://another.org</a>')
      end
    end

    describe "markdown option" do
      let(:content_with_markdown) do
        {
          "blocks" => [
            {
              "type" => "paragraph",
              "data" => {
                "text" => "Research on ADHD",
                "footnotes" => [
                  {
                    "id" => "fn-markdown",
                    "content" => "Smith, J. (2023). **Important study** on *ADHD treatment*. See https://example.com for details.",
                    "position" => 16
                  }
                ]
              }
            }
          ]
        }
      end

      it "renders markdown formatting when markdown is true" do
        renderer = described_class.new(content_with_markdown, markdown: true)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        expect(footnotes[0][:content]).to include("<strong>Important study</strong>")
        expect(footnotes[0][:content]).to include("<em>ADHD treatment</em>")
        expect(footnotes[0][:content]).to include('<a href="https://example.com"')
      end

      it "does not render markdown when markdown is false" do
        renderer = described_class.new(content_with_markdown, markdown: false)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        expect(footnotes[0][:content]).to include("**Important study**")
        expect(footnotes[0][:content]).to include("*ADHD treatment*")
        expect(footnotes[0][:content]).not_to include("<strong>")
        expect(footnotes[0][:content]).not_to include("<em>")
      end

      it "does not render markdown when markdown is not specified" do
        renderer = described_class.new(content_with_markdown)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        expect(footnotes[0][:content]).to include("**Important study**")
        expect(footnotes[0][:content]).to include("*ADHD treatment*")
      end

      it "renders inline code with markdown" do
        content = {
          "blocks" => [
            {
              "type" => "paragraph",
              "data" => {
                "text" => "Test",
                "footnotes" => [
                  {
                    "id" => "fn-code",
                    "content" => "Use the `process()` function for data processing.",
                    "position" => 4
                  }
                ]
              }
            }
          ]
        }

        renderer = described_class.new(content, markdown: true)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        expect(footnotes[0][:content]).to include("<code>process()</code>")
      end

      it "renders strikethrough with markdown" do
        content = {
          "blocks" => [
            {
              "type" => "paragraph",
              "data" => {
                "text" => "Test",
                "footnotes" => [
                  {
                    "id" => "fn-strike",
                    "content" => "This is ~~incorrect~~ information.",
                    "position" => 4
                  }
                ]
              }
            }
          ]
        }

        renderer = described_class.new(content, markdown: true)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        expect(footnotes[0][:content]).to include("<del>incorrect</del>")
      end

      it "handles markdown links with proper attributes" do
        content = {
          "blocks" => [
            {
              "type" => "paragraph",
              "data" => {
                "text" => "Test",
                "footnotes" => [
                  {
                    "id" => "fn-link",
                    "content" => "See [this study](https://example.com) for more information.",
                    "position" => 4
                  }
                ]
              }
            }
          ]
        }

        renderer = described_class.new(content, markdown: true)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        expect(footnotes[0][:content]).to include('<a href="https://example.com" target="_blank" rel="noopener noreferrer">this study</a>')
      end

      it "can use both markdown and autolink_urls together" do
        content = {
          "blocks" => [
            {
              "type" => "paragraph",
              "data" => {
                "text" => "Test",
                "footnotes" => [
                  {
                    "id" => "fn-both",
                    "content" => "Plain text with https://example.com URL",
                    "position" => 4
                  }
                ]
              }
            }
          ]
        }

        # When both markdown and autolink_urls are true, markdown processes first,
        # then autolink_urls runs (but skips already-linked URLs)
        renderer = described_class.new(content, markdown: true, autolink_urls: true)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        expect(footnotes[0][:content]).to include('<a href="https://example.com"')
        # Should only have one link tag (not doubled)
        expect(footnotes[0][:content].scan(%r{<a[^>]*href="https://example\.com"}).length).to eq(1)
      end

      it "strips wrapping paragraph tags from markdown output" do
        content = {
          "blocks" => [
            {
              "type" => "paragraph",
              "data" => {
                "text" => "Test",
                "footnotes" => [
                  {
                    "id" => "fn-para",
                    "content" => "Simple footnote text.",
                    "position" => 4
                  }
                ]
              }
            }
          ]
        }

        renderer = described_class.new(content, markdown: true)
        renderer.render

        footnotes = renderer.footnote_registry.processed_footnotes
        # The markdown processor wraps content in <p> tags, but we strip them
        # processed_footnotes content should not start with <p> wrapper
        expect(footnotes[0][:content]).not_to match(%r{^<p>.*</p>$}m)
      end
    end
  end
end

class Layout
  def initialize(template:, theme:, responsive:)
    @template = template
    @theme = theme
    @responsive = responsive
  end

  def render(content:, metadata:)
    %(<div class="#{@template}-layout #{@theme}" data-responsive="#{@responsive}">#{content}</div>)
  end
end

class Component
  def initialize(type:, data:, config:)
    @type = type
    @data = data
    @config = config
  end

  def render
    case @type
    when "header"
      %(<header data-sticky="#{@config[:sticky]}">#{@data}</header>)
    when "sidebar"
      %(<aside class="sidebar-#{@config[:position]}">#{Array(@data).join}</aside>)
    when "main"
      %(<main class="two-column-layout">#{@data}</main>)
    when "footer"
      footer_class = @config[:minimal] ? ' class="minimal-footer"' : ""
      %(<footer#{footer_class}>#{@data}</footer>)
    end
  end
end
