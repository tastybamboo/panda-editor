# frozen_string_literal: true

module EditorHelpers
  def normalize_html(html)
    # Remove newlines and normalize whitespace between tags
    # but preserve meaningful spaces within text content
    html
      .gsub(/\s*\n\s*/, "")      # Remove newlines and surrounding spaces
      .gsub(/>\s+</, "><")        # Remove spaces between tags
      .gsub(/\s{2,}/, " ")        # Collapse multiple spaces to single space
      .strip                      # Remove leading/trailing whitespace
  end
end

module EditorJsHelper
  def normalize_html(html)
    # Remove newlines and normalize whitespace between tags
    # but preserve meaningful spaces within text content
    html
      .gsub(/\s*\n\s*/, "")      # Remove newlines and surrounding spaces
      .gsub(/>\s+</, "><")        # Remove spaces between tags
      .gsub(/\s{2,}/, " ")        # Collapse multiple spaces to single space
      .strip                      # Remove leading/trailing whitespace
  end
end

RSpec.configure do |config|
  config.include EditorHelpers, editorjs: true
end
