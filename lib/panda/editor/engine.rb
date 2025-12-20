# frozen_string_literal: true

require 'rails'
require 'sanitize'

# Ensure panda-core is loaded first (provides ModuleRegistry)
require 'panda/core'
require 'panda/core/engine' if defined?(Rails)

module Panda
  module Editor
    class Engine < ::Rails::Engine
      isolate_namespace Panda::Editor

      config.generators do |g|
        g.test_framework :rspec
      end

      # Eager load converter classes
      config.to_prepare do
        require 'panda/editor/markdown_to_editor_js_converter'
        require 'panda/editor/html_to_editor_js_converter'
      end

      initializer 'panda_editor.assets' do |app|
        next unless app.config.respond_to?(:assets)

        app.config.assets.paths << root.join('app/javascript')
        app.config.assets.paths << root.join('public')
        app.config.assets.precompile += %w[panda/editor/*.js panda/editor/*.css]
      end

      # Create a separate importmap for panda-editor
      # This keeps the engine's JavaScript separate from the app's importmap
      # Admin uses panda_core_javascript helper which reads from ModuleRegistry
      initializer 'panda_editor.importmap', before: 'importmap' do |app|
        Panda::Editor.importmap = Importmap::Map.new.tap do |map|
          map.draw(Panda::Editor::Engine.root.join('config/importmap.rb'))
        end
      end
    end
  end
end

# Register with ModuleRegistry so admin can access the importmap
Panda::Core::ModuleRegistry.register(
  gem_name: 'panda-editor',
  engine: 'Panda::Editor::Engine',
  paths: {
    views: 'app/views/panda/editor/**/*.erb',
    components: 'app/components/panda/editor/**/*.rb',
    javascripts: 'app/javascript/panda/editor/**/*.js'
  }
)
