# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Analytics do
  before do
    described_class.reset!
  end

  describe ".providers" do
    it "includes local provider by default" do
      expect(described_class.providers).to include(local: Panda::CMS::Analytics::LocalProvider)
    end
  end

  describe ".register_provider" do
    it "registers a new provider" do
      mock_provider = Class.new(Panda::CMS::Analytics::Provider)

      described_class.register_provider(:test, mock_provider)

      expect(described_class.providers[:test]).to eq(mock_provider)
    end

    it "raises error if provider does not inherit from Provider" do
      expect {
        described_class.register_provider(:invalid, Class.new)
      }.to raise_error(ArgumentError, /must inherit from/)
    end
  end

  describe ".provider" do
    it "returns local provider by default" do
      expect(described_class.provider).to be_a(Panda::CMS::Analytics::LocalProvider)
    end

    it "returns configured provider" do
      described_class.current_provider_name = :local

      expect(described_class.provider).to be_a(Panda::CMS::Analytics::LocalProvider)
    end
  end

  describe ".available?" do
    it "returns true when provider is configured" do
      expect(described_class.available?).to be true
    end
  end

  describe ".configure" do
    it "yields self for configuration" do
      described_class.configure do |config|
        config.current_provider_name = :local
        config.provider_config = {test: true}
      end

      expect(described_class.current_provider_name).to eq(:local)
      expect(described_class.provider_config).to eq({test: true})
    end
  end
end
