# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Editor::ToolsConfigSerializer do
  describe "#serialize" do
    it "converts tool names to camelCase where mapped" do
      tools = {link_tool: {endpoint: "/api"}}
      result = described_class.new(tools).serialize
      expect(result).to have_key("linkTool")
      expect(result).not_to have_key("link_tool")
    end

    it "passes through unmapped tool names as strings" do
      tools = {paragraph: {}, header: {}}
      result = described_class.new(tools).serialize
      expect(result).to have_key("paragraph")
      expect(result).to have_key("header")
    end

    it "converts snake_case option keys to camelCase" do
      tools = {header: {default_level: 2, some_nested_option: true}}
      result = described_class.new(tools).serialize
      expect(result["header"]).to eq({"defaultLevel" => 2, "someNestedOption" => true})
    end

    it "handles nested hashes" do
      tools = {embed: {services: {youtube: true, vimeo: true}}}
      result = described_class.new(tools).serialize
      expect(result["embed"]["services"]).to eq({"youtube" => true, "vimeo" => true})
    end

    it "handles empty options" do
      tools = {paragraph: {}}
      result = described_class.new(tools).serialize
      expect(result["paragraph"]).to eq({})
    end

    it "handles empty tools hash" do
      result = described_class.new({}).serialize
      expect(result).to eq({})
    end

    it "preserves arrays" do
      tools = {header: {levels: [1, 2, 3]}}
      result = described_class.new(tools).serialize
      expect(result["header"]["levels"]).to eq([1, 2, 3])
    end
  end

  describe "#to_json" do
    it "returns valid JSON" do
      tools = {paragraph: {}, header: {default_level: 2}}
      json = described_class.new(tools).to_json
      parsed = JSON.parse(json)
      expect(parsed).to have_key("paragraph")
      expect(parsed["header"]["defaultLevel"]).to eq(2)
    end
  end
end
