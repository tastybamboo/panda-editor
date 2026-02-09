# frozen_string_literal: true

module Panda
  module Editor
    module Blocks
      class Attaches < Base
        def render
          file = data["file"] || {}
          url = file["url"]
          name = sanitize(file["name"].to_s)
          size = file["size"]
          extension = sanitize(file["extension"].to_s)
          title = sanitize(data["title"].presence || name)

          html_safe(<<~HTML)
            <div class="attaches-tool">
              <a href="#{ERB::Util.html_escape(url)}" target="_blank" rel="noopener noreferrer" download>
                <div class="attaches-tool__icon">#{extension_badge(extension)}</div>
                <div class="attaches-tool__content">
                  <div class="attaches-tool__title">#{title}</div>
                  #{size_element(size, extension)}
                </div>
              </a>
            </div>
          HTML
        end

        private

        def extension_badge(extension)
          return "" if extension.blank?

          "<span class=\"attaches-tool__extension\">#{extension.upcase}</span>"
        end

        def size_element(size, extension)
          parts = []
          parts << human_file_size(size) if size.present? && size.to_i > 0
          parts << extension.upcase if extension.present?
          return "" if parts.empty?

          "<span class=\"attaches-tool__size\">#{parts.join(" ")}</span>"
        end

        def human_file_size(bytes)
          bytes = bytes.to_i
          return "0 B" if bytes == 0

          units = %w[B KB MB GB]
          exp = (Math.log(bytes) / Math.log(1024)).to_i
          exp = [exp, units.length - 1].min
          size = (bytes.to_f / (1024**exp)).round(1)
          "#{size} #{units[exp]}"
        end
      end
    end
  end
end
