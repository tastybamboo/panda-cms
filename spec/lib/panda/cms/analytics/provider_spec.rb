# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Analytics::Provider do
  let(:provider) { described_class.new({test: true}) }

  describe ".slug" do
    it "derives from class name" do
      expect(described_class.slug).to eq(:provider)
    end
  end

  describe ".display_name" do
    it "derives from class name" do
      expect(described_class.display_name).to eq("Provider")
    end
  end

  describe ".icon" do
    it "returns default icon" do
      expect(described_class.icon).to eq("fa-solid fa-chart-line")
    end
  end

  describe ".has_settings_page?" do
    it "returns false by default" do
      expect(described_class.has_settings_page?).to be false
    end
  end

  describe "#supports_tracking?" do
    it "returns false by default" do
      expect(provider.supports_tracking?).to be false
    end
  end

  describe "#tracking_script" do
    it "returns nil by default" do
      expect(provider.tracking_script).to be_nil
    end
  end

  describe "#tracking_configured?" do
    it "returns false by default" do
      expect(provider.tracking_configured?).to be false
    end
  end

  describe "#name" do
    it "delegates to display_name" do
      expect(provider.name).to eq("Provider")
    end
  end

  describe "#config" do
    it "returns the configuration hash" do
      expect(provider.config).to eq({test: true})
    end
  end

  describe "subclass metadata" do
    let(:custom_provider) do
      Class.new(described_class) do
        def self.name = "Panda::CMS::Analytics::CustomTestProvider"
        def self.slug = :custom_test
        def self.display_name = "Custom Test"
        def self.icon = "fa-solid fa-flask"
        def self.has_settings_page? = true
      end
    end

    it "allows subclasses to override class methods" do
      expect(custom_provider.slug).to eq(:custom_test)
      expect(custom_provider.display_name).to eq("Custom Test")
      expect(custom_provider.icon).to eq("fa-solid fa-flask")
      expect(custom_provider.has_settings_page?).to be true
    end
  end
end
