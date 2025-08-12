# frozen_string_literal: true

require_relative "lib/panda/editor/version"

Gem::Specification.new do |spec|
  spec.name = "panda-editor"
  spec.version = Panda::Editor::VERSION
  spec.authors = ["Panda CMS Team"]
  spec.email = ["hello@pandacms.io"]

  spec.summary = "EditorJS integration for Rails applications"
  spec.description = "A modular, extensible rich text editor using EditorJS for Rails applications. Extracted from Panda CMS."
  spec.homepage = "https://github.com/tastybamboo/panda-editor"
  spec.license = "BSD-3-Clause"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tastybamboo/panda-editor"
  spec.metadata["changelog_uri"] = "https://github.com/tastybamboo/panda-editor/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile]) ||
        f.end_with?(".gem")
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Rails dependencies
  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "sanitize", "~> 6.0"

  # Development dependencies
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2"
  spec.add_development_dependency "standardrb", "~> 1.0"
end
