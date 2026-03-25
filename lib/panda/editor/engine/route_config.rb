# frozen_string_literal: true

module Panda
  module Editor
    class Engine < ::Rails::Engine
      module RouteConfig
        extend ActiveSupport::Concern

        included do
          config.after_initialize do |app|
            app.routes.append do
              scope "panda/editor", module: "panda/editor", as: "panda_editor" do
                get "pdf_url/:signed_id", to: "pdf_urls#show", as: :pdf_url
              end
            end
          end
        end
      end
    end
  end
end
