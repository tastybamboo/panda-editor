# frozen_string_literal: true

require "rails"
require "sanitize"

module Panda
  module Editor
    class Engine < ::Rails::Engine
      isolate_namespace Panda::Editor

      config.generators do |g|
        g.test_framework :rspec
      end

      # Allow applications to configure editor tools
      config.editor_js_tools = []

      # Custom block renderers
      config.custom_renderers = {}

      initializer "panda_editor.assets" do |app|
        app.config.assets.paths << root.join("app/javascript")
        app.config.assets.paths << root.join("public")
        app.config.assets.precompile += %w[panda/editor/*.js panda/editor/*.css]
      end

      initializer "panda_editor.importmap", before: "importmap" do |app|
        if app.config.respond_to?(:importmap)
          app.config.importmap.paths << root.join("config/importmap.rb")
        end
      end
    end
  end
end
