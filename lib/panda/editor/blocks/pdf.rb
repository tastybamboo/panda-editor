# frozen_string_literal: true

module Panda
  module Editor
    module Blocks
      class Pdf < Base
        def render
          file = data["file"] || {}
          signed_id = file["signed_id"]
          return "" if signed_id.blank?

          title = sanitize(file["name"].to_s)
          pdf_url_endpoint = "/panda/editor/pdf_url/#{ERB::Util.url_encode(signed_id)}"

          html_safe("#{pdf_assets_tags}#{viewer_html(pdf_url_endpoint, title)}")
        end

        private

        def viewer_html(pdf_url_endpoint, title)
          <<~HTML
            <div class="panda-pdf-viewer" data-pdf-url-endpoint="#{ERB::Util.html_escape(pdf_url_endpoint)}" role="document" aria-label="#{ERB::Util.html_escape(title)}">
              <div class="panda-pdf-viewer__container">
                <canvas class="panda-pdf-viewer__canvas"></canvas>
              </div>
              <div class="panda-pdf-viewer__controls">
                <button class="panda-pdf-viewer__prev" aria-label="Previous page" disabled>&lsaquo; Prev</button>
                <span class="panda-pdf-viewer__page-info">Loading...</span>
                <button class="panda-pdf-viewer__next" aria-label="Next page" disabled>Next &rsaquo;</button>
              </div>
              <noscript>
                <p>PDF viewer requires JavaScript.</p>
              </noscript>
            </div>
          HTML
        end

        def pdf_assets_tags
          return "" if options[:_pdf_assets_included]
          options[:_pdf_assets_included] = true

          <<~HTML
            <link rel="stylesheet" href="/panda/editor/pdf_viewer.css">
            <script src="/panda/editor/pdf_viewer.js" defer></script>
          HTML
        end
      end
    end
  end
end
