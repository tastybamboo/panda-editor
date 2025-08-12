# frozen_string_literal: true

require "spec_helper"

# Load the Rails engine
require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "active_support/railtie"

# Require the gem itself
require "panda/editor"

# Configure Rails for testing
ENV["RAILS_ENV"] ||= "test"

# Create a minimal Rails application for testing
module TestApp
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.root = File.expand_path("../", __dir__)
    config.active_support.deprecation = :stderr
  end
end

# Initialize the Rails application
Rails.application.initialize! unless Rails.application.initialized?

require "rspec/rails"

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end