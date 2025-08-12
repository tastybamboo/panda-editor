# frozen_string_literal: true

module EditorHelpers
  def normalize_html(html)
    html.gsub(/\s+/, " ").strip
  end
end

module EditorJsHelper
  def normalize_html(html)
    html.gsub(/\s+/, " ").strip
  end
end

RSpec.configure do |config|
  config.include EditorHelpers, editorjs: true
end