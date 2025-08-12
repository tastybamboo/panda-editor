# frozen_string_literal: true

require "net/http"
require "json"

module Panda
  module Editor
    class AssetLoader
      GITHUB_RELEASES_URL = "https://api.github.com/repos/tastybamboo/panda-editor/releases/latest"
      ASSET_CACHE_DIR = Rails.root.join("tmp", "panda_editor_assets")

      class << self
        def load_assets
          if use_compiled_assets?
            load_compiled_assets
          else
            load_development_assets
          end
        end

        def javascript_url
          if use_compiled_assets?
            compiled_javascript_url
          else
            "/assets/panda/editor/application.js"
          end
        end

        def stylesheet_url
          if use_compiled_assets?
            compiled_stylesheet_url
          else
            "/assets/panda/editor/application.css"
          end
        end

        private

        def use_compiled_assets?
          Rails.env.production? ||
            Rails.env.test? ||
            ENV["PANDA_EDITOR_USE_COMPILED_ASSETS"] == "true"
        end

        def load_compiled_assets
          ensure_assets_downloaded
          {
            javascript: compiled_javascript_url,
            stylesheet: compiled_stylesheet_url
          }
        end

        def load_development_assets
          {
            javascript: "/assets/panda/editor/application.js",
            stylesheet: "/assets/panda/editor/application.css"
          }
        end

        def compiled_javascript_url
          asset_path = find_latest_asset("js")
          asset_path ? "/panda-editor-assets/#{File.basename(asset_path)}" : nil
        end

        def compiled_stylesheet_url
          asset_path = find_latest_asset("css")
          asset_path ? "/panda-editor-assets/#{File.basename(asset_path)}" : nil
        end

        def find_latest_asset(extension)
          pattern = Rails.root.join("public", "panda-editor-assets", "panda-editor-*.#{extension}")
          Dir.glob(pattern).max_by { |f| File.mtime(f) }
        end

        def ensure_assets_downloaded
          return if assets_exist?

          download_assets_from_github
        end

        def assets_exist?
          js_exists = Dir.glob(Rails.root.join("public", "panda-editor-assets", "panda-editor-*.js")).any?
          css_exists = Dir.glob(Rails.root.join("public", "panda-editor-assets", "panda-editor-*.css")).any?
          js_exists && css_exists
        end

        def download_assets_from_github
          Rails.logger.info "[Panda Editor] Downloading assets from GitHub releases..."

          begin
            release_data = fetch_latest_release
            download_release_assets(release_data["assets"])
          rescue => e
            Rails.logger.error "[Panda Editor] Failed to download assets: #{e.message}"
            use_fallback_assets
          end
        end

        def fetch_latest_release
          uri = URI(GITHUB_RELEASES_URL)
          response = Net::HTTP.get_response(uri)

          if response.code == "200"
            JSON.parse(response.body)
          else
            raise "GitHub API returned #{response.code}"
          end
        end

        def download_release_assets(assets)
          assets.each do |asset|
            next unless asset["name"].match?(/panda-editor.*\.(js|css)$/)

            download_asset(asset)
          end
        end

        def download_asset(asset)
          uri = URI(asset["browser_download_url"])
          response = Net::HTTP.get_response(uri)

          if response.code == "200"
            save_asset(asset["name"], response.body)
          end
        end

        def save_asset(filename, content)
          dir = Rails.root.join("public", "panda-editor-assets")
          FileUtils.mkdir_p(dir)

          File.write(dir.join(filename), content)
          Rails.logger.info "[Panda Editor] Downloaded #{filename}"
        end

        def use_fallback_assets
          Rails.logger.warn "[Panda Editor] Using fallback embedded assets"
          # Copy embedded assets from gem to public directory
          copy_embedded_assets
        end

        def copy_embedded_assets
          source_dir = Panda::Editor::Engine.root.join("public", "panda-editor-assets")
          dest_dir = Rails.root.join("public", "panda-editor-assets")

          FileUtils.mkdir_p(dest_dir)
          FileUtils.cp_r(Dir.glob(source_dir.join("*")), dest_dir)
        end
      end
    end
  end
end
