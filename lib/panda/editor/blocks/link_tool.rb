# frozen_string_literal: true

module Panda
  module Editor
    module Blocks
      class LinkTool < Base
        def render
          link = data["link"]
          meta = data["meta"] || {}
          title = sanitize(meta["title"].presence || link)
          description = sanitize(meta["description"].to_s)
          image_url = meta.dig("image", "url")

          html_safe(<<~HTML)
            <div class="link-tool">
              <a href="#{ERB::Util.html_escape(link)}" target="_blank" rel="nofollow noopener noreferrer">
                #{image_element(image_url)}
                <div class="link-tool__content">
                  <div class="link-tool__title">#{title}</div>
                  #{description_element(description)}
                  <span class="link-tool__anchor">#{ERB::Util.html_escape(link)}</span>
                </div>
              </a>
            </div>
          HTML
        end

        private

        def image_element(url)
          return "" if url.blank?

          "<div class=\"link-tool__image\"><img src=\"#{ERB::Util.html_escape(url)}\" alt=\"\" loading=\"lazy\" /></div>"
        end

        def description_element(description)
          return "" if description.blank?

          "<p class=\"link-tool__description\">#{description}</p>"
        end
      end
    end
  end
end
