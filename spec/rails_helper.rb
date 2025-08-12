# frozen_string_literal: true

require "spec_helper"

# Configure Rails for testing
ENV["RAILS_ENV"] ||= "test"

# Load Rails components we need
require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "active_support/railtie"

# Create a minimal Rails application for testing
module TestApp
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.root = File.expand_path("../", __dir__)
    config.active_support.deprecation = :stderr

    # Stub out assets configuration for the engine
    config.respond_to?(:assets) || config.define_singleton_method(:assets) { @assets ||= ActiveSupport::OrderedOptions.new }
    config.assets.paths ||= []
    config.assets.precompile ||= []
  end
end

# Initialize application before loading the engine
Rails.application.initialize!

# Now load the engine
require "panda/editor"

require "rspec/rails"

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
