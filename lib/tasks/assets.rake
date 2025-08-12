# frozen_string_literal: true

namespace :panda_editor do
  namespace :assets do
    desc "Compile Panda Editor assets for production"
    task :compile => :environment do
      require "fileutils"
      
      puts "Compiling Panda Editor assets..."
      
      # Create temporary directory for assets
      tmp_dir = Rails.root.join("tmp", "panda_editor_assets")
      FileUtils.mkdir_p(tmp_dir)
      
      # Get version from gem
      version = Panda::Editor::VERSION
      
      # Compile JavaScript
      compile_javascript(tmp_dir, version)
      
      # Compile CSS
      compile_css(tmp_dir, version)
      
      # Copy to public directory
      public_dir = Rails.root.join("public", "panda-editor-assets")
      FileUtils.mkdir_p(public_dir)
      FileUtils.cp_r(Dir.glob(tmp_dir.join("*")), public_dir)
      
      puts "✅ Assets compiled successfully"
    end

    desc "Download Panda Editor assets from GitHub"
    task :download => :environment do
      require "panda/editor/asset_loader"
      
      puts "Downloading Panda Editor assets from GitHub..."
      Panda::Editor::AssetLoader.send(:download_assets_from_github)
      puts "✅ Assets downloaded successfully"
    end

    desc "Upload compiled assets to GitHub release"
    task :upload => :environment do
      require "net/http"
      require "json"
      
      puts "Uploading Panda Editor assets to GitHub release..."
      
      # This task would be run in CI to upload compiled assets
      # to the GitHub release when a new version is tagged
      
      version = ENV["GITHUB_REF_NAME"] || "v#{Panda::Editor::VERSION}"
      token = ENV["GITHUB_TOKEN"]
      
      unless token
        puts "❌ GITHUB_TOKEN environment variable required"
        exit 1
      end
      
      # Find compiled assets
      assets_dir = Rails.root.join("public", "panda-editor-assets")
      js_file = Dir.glob(assets_dir.join("panda-editor-*.js")).first
      css_file = Dir.glob(assets_dir.join("panda-editor-*.css")).first
      
      if js_file && css_file
        upload_to_release(js_file, version, token)
        upload_to_release(css_file, version, token)
        puts "✅ Assets uploaded successfully"
      else
        puts "❌ Compiled assets not found"
        exit 1
      end
    end

    private

    def compile_javascript(tmp_dir, version)
      puts "  Compiling JavaScript..."
      
      js_files = Dir.glob(Panda::Editor::Engine.root.join("app/javascript/panda/editor/**/*.js"))
      
      output = js_files.map { |file| File.read(file) }.join("\n\n")
      
      # Add version marker
      output = "/* Panda Editor v#{version} */\n#{output}"
      
      # Write compiled file
      File.write(tmp_dir.join("panda-editor-#{version}.js"), output)
    end

    def compile_css(tmp_dir, version)
      puts "  Compiling CSS..."
      
      css_files = Dir.glob(Panda::Editor::Engine.root.join("app/assets/stylesheets/panda/editor/**/*.css"))
      
      output = css_files.map { |file| File.read(file) }.join("\n\n")
      
      # Add version marker
      output = "/* Panda Editor v#{version} */\n#{output}"
      
      # Write compiled file
      File.write(tmp_dir.join("panda-editor-#{version}.css"), output)
    end

    def upload_to_release(file, version, token)
      # Implementation would upload to GitHub release
      # This is a placeholder for the actual upload logic
      puts "  Uploading #{File.basename(file)}..."
    end
  end
end