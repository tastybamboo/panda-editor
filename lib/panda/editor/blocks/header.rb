# frozen_string_literal: true

module Panda
  module Editor
    module Blocks
      class Header < Base
        def render
          content = sanitize(data["text"])
          level = data["level"] || 2
          slug = unique_slug(generate_slug(content))
          html_safe(%(<h#{level} id="#{slug}">#{content}</h#{level}>))
        end

        private

        def generate_slug(text)
          text.gsub(/<[^>]+>/, "")  # Strip HTML tags
            .strip
            .downcase
            .gsub(/[^a-z0-9\s-]/, "") # Remove non-alphanumeric (keep spaces/hyphens)
            .gsub(/\s+/, "-")          # Spaces to hyphens
            .squeeze("-")              # Collapse multiple hyphens
            .sub(/\A-/, "")            # Strip leading hyphen
            .sub(/-\z/, "")            # Strip trailing hyphen
        end

        def unique_slug(slug)
          registry = options[:slug_registry]
          return slug unless registry

          registry[slug] += 1
          (registry[slug] > 1) ? "#{slug}-#{registry[slug]}" : slug
        end
      end
    end
  end
end
