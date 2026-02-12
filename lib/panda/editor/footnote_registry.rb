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

      def processed_footnotes
        return [] if @footnotes.empty?

        @footnotes.map.with_index do |footnote, index|
          {
            number: index + 1,
            id: footnote[:id],
            content: process_content(footnote[:content])
          }
        end
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
        # If content already contains HTML links, it's pre-formatted and
        # reprocessing would produce broken nested <a> tags
        return content if content.include?("<a ")

        content = render_markdown(content) if @markdown
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
