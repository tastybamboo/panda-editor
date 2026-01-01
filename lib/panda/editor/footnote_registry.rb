# frozen_string_literal: true

require "redcarpet"

module Panda
  module Editor
    class FootnoteRegistry
      attr_reader :footnotes

      def initialize(autolink_urls: false, markdown: false)
        @footnotes = []
        @footnote_ids = {}
        @autolink_urls = autolink_urls
        @markdown = markdown
      end

      def add(id:, content:)
        # Return existing number if this ID was already registered
        return @footnote_ids[id] if @footnote_ids[id]

        # Add new footnote
        @footnotes << {id: id, content: content}
        number = @footnotes.length

        # Cache the number for this ID
        @footnote_ids[id] = number

        number
      end

      def render_sources_section
        return "" if @footnotes.empty?

        footnote_items = @footnotes.map.with_index do |footnote, index|
          number = index + 1
          content = process_content(footnote[:content])
          <<~HTML.strip
            <li id="fn:#{number}">
              <p>
                #{content}
                <a href="#fnref:#{number}" class="footnote-backref">↩</a>
              </p>
            </li>
          HTML
        end.join("\n")

        <<~HTML
          <div class="mx-6 lg:mx-8 mt-4 mb-8">
            <div class="footnotes-section bg-gray-50 rounded-lg overflow-hidden">
              <button class="footnotes-header w-full px-4 py-3 flex items-center justify-between cursor-pointer hover:bg-gray-100 transition-colors" data-footnotes-target="toggle" data-action="click->footnotes#toggle">
                <h3 class="text-sm font-unbounded font-medium text-gray-900 m-0">Sources/References</h3>
                <svg class="footnotes-chevron w-5 h-5 text-gray-600" data-footnotes-target="chevron" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                </svg>
              </button>
              <div class="footnotes-content" data-footnotes-target="content">
                <ol class="footnotes text-sm text-gray-700 space-y-2 px-4 pb-3">
          #{footnote_items}
                </ol>
              </div>
            </div>
          </div>
        HTML
      end

      def any?
        @footnotes.any?
      end

      def get_content(id)
        footnote = @footnotes.find { |fn| fn[:id] == id }
        footnote ? process_content(footnote[:content]) : nil
      end

      private

      def process_content(content)
        # Apply markdown processing if enabled
        content = render_markdown(content) if @markdown

        # Apply URL autolinking if enabled
        # Note: Markdown already includes autolink, but custom autolink_urls can still be used
        # if needed for additional URL patterns. The autolink_urls method skips already-linked URLs.
        content = autolink_urls(content) if @autolink_urls

        content
      end

      def render_markdown(text)
        # Configure Redcarpet with safe options for footnotes
        renderer = Redcarpet::Render::HTML.new(
          filter_html: false,
          no_images: true,
          no_styles: true,
          safe_links_only: true,
          link_attributes: {target: "_blank", rel: "noopener noreferrer"}
        )

        markdown = Redcarpet::Markdown.new(
          renderer,
          autolink: true,
          space_after_headers: true,
          fenced_code_blocks: false,
          no_intra_emphasis: true,
          strikethrough: true,
          superscript: false,
          underline: false
        )

        # Render markdown and strip the wrapping <p> tags if present
        # since we're already wrapping in <p> tags in the template
        html = markdown.render(text).strip
        html.gsub(%r{^<p>(.*)</p>$}m, '\1')
      end

      def autolink_urls(text)
        # Regex to match URLs that aren't already in <a> tags
        # Matches http://, https://, and other common protocols
        url_pattern = %r{
          (?<!["'>])                           # Not preceded by quotes or >
          \b                                    # Word boundary
          (https?://|ftp://|www\.)             # Protocol or www
          [^\s<>"']+                           # URL characters (not whitespace, <, >, quotes)
          [^\s<>"'.,;:!?)\]]                   # Ends with non-punctuation
        }x

        # Don't replace URLs that are already in <a> tags
        text.gsub(url_pattern) do |url|
          # Skip if this URL is already part of an href attribute
          before_match = ::Regexp.last_match.pre_match
          if /<a[^>]*href\s*=\s*["']?\z/i.match?(before_match)
            url
          else
            # Add protocol if missing
            full_url = url.start_with?("www.") ? "https://#{url}" : url
            %(<a href="#{full_url}" target="_blank" rel="noopener noreferrer">#{url}</a>)
          end
        end
      end
    end
  end
end
