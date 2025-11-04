# frozen_string_literal: true

require 'rails'
require 'sanitize'

module Panda
  module Editor
    class Engine < ::Rails::Engine
      isolate_namespace Panda::Editor

      config.generators do |g|
        g.test_framework :rspec
      end

      initializer 'panda_editor.assets' do |app|
        next unless app.config.respond_to?(:assets)

        app.config.assets.paths << root.join('app/javascript')
        app.config.assets.paths << root.join('public')
        app.config.assets.precompile += %w[panda/editor/*.js panda/editor/*.css]
      end

      initializer 'panda_editor.importmap', before: 'importmap' do |app|
        app.config.importmap.paths << root.join('config/importmap.rb') if app.config.respond_to?(:importmap)
      end
    end
  end
end
