# frozen_string_literal: true

require "json"

module Panda
  module Editor
    module Content
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Validations
        include ActiveModel::Callbacks

        before_save :generate_cached_content
      end

      def content=(value)
        if value.is_a?(Hash)
          super(value.to_json)
        else
          super
        end
      end

      def content
        value = super
        if value.is_a?(String)
          begin
            JSON.parse(value)
          rescue JSON::ParserError
            value
          end
        else
          value
        end
      end

      def generate_cached_content
        renderer_options = {
          autolink_urls: true,
          custom_renderers: Panda::Editor.config.custom_renderers
        }

        if content.is_a?(String)
          begin
            parsed_content = JSON.parse(content)
            self.cached_content = if parsed_content.is_a?(Hash) && parsed_content["blocks"].present?
              render_and_cache_with_footnotes(parsed_content, renderer_options)
            else
              content
            end
          rescue JSON::ParserError
            # If it's not JSON, treat it as plain text
            self.cached_content = content
          end
        elsif content.is_a?(Hash) && content["blocks"].present?
          # Process EditorJS content
          self.cached_content = render_and_cache_with_footnotes(content, renderer_options)
        else
          # For any other case, store as is
          self.cached_content = content.to_s
        end
      end

      private

      def render_and_cache_with_footnotes(parsed_content, renderer_options)
        renderer = Panda::Editor::Renderer.new(parsed_content, renderer_options)
        html = renderer.render

        # Store structured data with pre-computed footnotes for JSONB columns,
        # plain HTML for text columns (e.g. Post.cached_content)
        column = self.class.column_for_attribute(:cached_content)
        if column.type == :jsonb
          {
            "html" => html,
            "footnotes" => renderer.footnote_registry.processed_footnotes
          }
        else
          html
        end
      end
    end
  end
end
